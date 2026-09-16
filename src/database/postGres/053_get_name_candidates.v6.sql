-- get_name_candidates (048) with a rank ceiling on the unfiltered path.
--
-- scoped joined every popularity row to given_names and the bridge, then grouped
-- 116,550 rows down to 104,819 to keep each name's best rank. The grouping was
-- almost a no-op, but Postgres had to build a hash table of all 105,000 rows to
-- discover that, and it did not fit in work_mem, so it spilled to disk: 220ms of
-- a 413ms call.
--
-- The tiers only ever reach ranks offset + 5,000. Everything past that is tier 4,
-- which has no quota and is served only by the backfill. So on a call where the
-- three bands can fill the limit on their own, the work of loading and grouping
-- the other ~95,000 names is thrown away. Capping scoped at the tier-3 boundary
-- removes it. Measured against prod: 413ms to 103ms.
--
-- The ceiling is applied ONLY when no filters are set. That is the app's opening
-- request and by far the most common one, and it cannot come up short: the capped
-- pool holds 9,198 live names and a request asks for 50.
--
-- Any filter at all and the function behaves exactly as 048 did, same speed and
-- same results. This matters because a narrow filter can have most of its names
-- ranked past the ceiling — one culture we measured has 124 names, only 47 of
-- them inside the top 5,000 — and capping it would quietly return 47 names where
-- 124 exist. Deciding per call whether the ceiling is safe means counting the
-- matches first, and the count needs the gender, language and culture conditions
-- written out a second and third time. Three copies of the filter logic in one
-- function is a worse bug than the one it prevents, so the ceiling is simply not
-- applied when it could do harm.
--
-- Left on the table: a gender-only filter is broad enough to cap safely and still
-- runs at 413ms. Worth revisiting as its own change, with a way to share the
-- filter conditions rather than repeat them.
--
-- v_offset is counted directly from the user's own rows rather than from scoped,
-- because the ceiling has to be known before scoped runs. It matches what the
-- offset_counted CTE computes on the unfiltered path: candidates are only ever
-- served from within the windows, so every name a user has decided on ranks at or
-- below the current ceiling and is counted either way. The CTE is left exactly as
-- 048 has it and still drives the tier boundaries.
--
-- The return type is unchanged, so CREATE OR REPLACE is enough. Re-running
-- 048_get_name_candidates.v5.sql restores the previous behaviour.

CREATE OR REPLACE FUNCTION get_name_candidates(
  p_user_id INT,
  p_gender_ids INT[] DEFAULT NULL,
  p_decade_ids INT[] DEFAULT NULL,
  p_language_ids INT[] DEFAULT NULL,
  p_culture_ids INT[] DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_exclude_bridge_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  out_given_custom_name_bridge_id INT,
  out_given_name TEXT,
  out_etymology JSON
) AS $$
DECLARE
  v_genders gender[];
  v_limit INT;
  v_quota_1 INT;
  v_quota_2 INT;
  v_quota_3 INT;
  v_offset INT;
  v_rank_cap INT;
BEGIN
  -- Ids that resolve to nothing match nothing, rather than being read as an
  -- absent filter. A silently ignored filter is the harder bug to notice.
  IF p_gender_ids IS NOT NULL THEN
    SELECT array_agg(g.value)
    INTO v_genders
    FROM genders g
    WHERE g.id = ANY(p_gender_ids);
  END IF;

  v_limit   := GREATEST(1, COALESCE(NULLIF(p_limit, 0), 50));
  v_quota_1 := ROUND(v_limit * 0.7);
  v_quota_2 := ROUND(v_limit * 0.2);
  v_quota_3 := v_limit - v_quota_1 - v_quota_2;

  -- Null leaves scoped uncapped, which is 048's behaviour. Only the unfiltered
  -- path sets a ceiling; see the header for why.
  v_rank_cap := NULL;

  IF p_gender_ids IS NULL
     AND p_decade_ids IS NULL
     AND p_language_ids IS NULL
     AND p_culture_ids IS NULL
  THEN
    -- Driven from the user's own state rows, so the work is proportional to what
    -- they have decided rather than to the whole name set. Measured at 2ms for a
    -- user 228 names deep. The joins are here so a state row pointing at
    -- something with no popularity row is not counted, matching scoped.
    SELECT count(*)::int
    INTO v_offset
    FROM user_given_names_states u
    WHERE u.user_id = p_user_id
      AND u.state IN ('rejected', 'approved')
      AND EXISTS (
        SELECT 1
        FROM given_custom_name_bridge b
        JOIN given_names gn
          ON gn.id = b.given_name_id
        JOIN given_name_popularity_overall o
          ON o.given_name_id = gn.id
        WHERE b.id = u.given_custom_name_bridge_id
      );

    v_rank_cap := v_offset + 5000;
  END IF;

  RETURN QUERY
  WITH source AS (
    SELECT
      d.given_name_id,
      d.rank,
      d.female_share,
      d.gender_difference
    FROM given_name_popularity_by_decade d
    WHERE p_decade_ids IS NOT NULL
      AND d.decade_id = ANY(p_decade_ids)

    UNION ALL

    SELECT
      o.given_name_id,
      o.rank,
      o.female_share,
      o.gender_difference
    FROM given_name_popularity_overall o
    WHERE p_decade_ids IS NULL
  ),

  -- One row per name, carrying its best rank across whatever was selected.
  scoped AS (
    SELECT
      b.id AS bid,
      gn.id AS given_name_id,
      gn.given_name,
      MIN(s.rank) AS rank
    FROM source s
    JOIN given_names gn
      ON gn.id = s.given_name_id
    JOIN given_custom_name_bridge b
      ON b.given_name_id = gn.id

    WHERE (
        -- The tiers never reach past this, so nothing below it is loaded.
        v_rank_cap IS NULL
        OR s.rank <= v_rank_cap
      )

      AND (
        p_gender_ids IS NULL
        OR (
          CASE
            WHEN s.gender_difference IS NULL THEN NULL::gender
            WHEN s.gender_difference <= 0.40 THEN 'neutral'::gender
            WHEN s.female_share > 0.50 THEN 'female'::gender
            ELSE 'male'::gender
          END
        ) = ANY(v_genders)
      )

      AND (
        p_language_ids IS NULL
        OR EXISTS (
          SELECT 1
          FROM given_name_language_bridge gnlb
          WHERE gnlb.given_name_id = gn.id
            AND gnlb.language_id = ANY(p_language_ids)
        )
      )

      AND (
        p_culture_ids IS NULL
        OR EXISTS (
          SELECT 1
          FROM given_name_culture_bridge gncb
          WHERE gncb.given_name_id = gn.id
            AND gncb.culture_id = ANY(p_culture_ids)
        )
      )

    GROUP BY b.id, gn.id, gn.given_name
  ),

  -- How far the bands have rolled: names already decided on under these filters.
  -- Snoozes do not count, since a snoozed name comes back.
  offset_counted AS (
    SELECT count(*)::int AS n
    FROM scoped s
    JOIN user_given_names_states u
      ON u.given_custom_name_bridge_id = s.bid
     AND u.user_id = p_user_id
     AND u.state IN ('rejected', 'approved')
  ),

  live AS (
    SELECT s.*
    FROM scoped s
    WHERE (
        p_exclude_bridge_ids IS NULL
        OR s.bid <> ALL(p_exclude_bridge_ids)
      )
      AND NOT EXISTS (
        SELECT 1
        FROM user_given_names_states u
        WHERE u.user_id = p_user_id
          AND u.given_custom_name_bridge_id = s.bid
          AND (
            u.state IN ('rejected', 'approved')
            OR (
              u.state = 'snoozed'
              AND u.date_created > NOW() - INTERVAL '24 hours'
            )
          )
      )
  ),

  pool AS (
    SELECT count(*)::int AS n FROM live
  ),

  tiered AS (
    SELECT
      l.bid,
      l.given_name_id,
      l.given_name,
      l.rank,
      CASE
        -- Too small a pool for bands to mean anything; everything is tier one and
        -- the backfill serves the rest.
        WHEN (SELECT n FROM pool) < 300 THEN 1
        WHEN l.rank <= (SELECT n FROM offset_counted) + 500  THEN 1
        WHEN l.rank <= (SELECT n FROM offset_counted) + 2000 THEN 2
        WHEN l.rank <= (SELECT n FROM offset_counted) + 5000 THEN 3
        ELSE 4
      END AS tier
    FROM live l
  ),

  -- Flat random within each band, so a batch is not ranks 1, 2, 3, 4.
  banded AS MATERIALIZED (
    (SELECT t.bid, t.given_name_id, t.given_name, t.rank FROM tiered t WHERE t.tier = 1 ORDER BY random() LIMIT v_quota_1)
    UNION ALL
    (SELECT t.bid, t.given_name_id, t.given_name, t.rank FROM tiered t WHERE t.tier = 2 ORDER BY random() LIMIT v_quota_2)
    UNION ALL
    (SELECT t.bid, t.given_name_id, t.given_name, t.rank FROM tiered t WHERE t.tier = 3 ORDER BY random() LIMIT v_quota_3)
  ),

  -- A band can come up short — narrow filters, or a roll that has outrun the
  -- names. Top up from whatever is left, nearest ranks first, tier four included,
  -- so a full batch is returned whenever the names exist to fill it.
  filled AS MATERIALIZED (
    SELECT b.bid, b.given_name_id, b.given_name FROM banded b

    UNION ALL

    (
      SELECT t.bid, t.given_name_id, t.given_name
      FROM tiered t
      WHERE NOT EXISTS (SELECT 1 FROM banded b WHERE b.bid = t.bid)
      ORDER BY t.rank, random()
      LIMIT GREATEST(0, v_limit - (SELECT count(*)::int FROM banded))
    )
  )

  -- Shuffled so the tiers arrive interleaved rather than in blocks; the app serves
  -- these one at a time. Etymology is built here, for the returned rows only.
  SELECT
    f.bid,
    f.given_name,
    get_given_name_etymology(f.given_name_id)
  FROM filled f
  ORDER BY random();

END;
$$ LANGUAGE plpgsql;
