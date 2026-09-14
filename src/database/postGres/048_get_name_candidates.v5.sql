-- get_name_candidates (046) with its etymology built by get_given_name_etymology
-- (047) instead of inline, so the approved names list can share it. Nothing else
-- changes: the signature, bands, backfill and output are exactly as in 046, which
-- carries the reasoning for all of them.
--
-- The return type is unchanged, so CREATE OR REPLACE is enough.

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
