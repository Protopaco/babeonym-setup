-- Rewrites get_name_candidates (from 033) around what the app is actually for.
--
-- The old query aimed at a popularity percentile the user set on a slider. That
-- slider was never built, and the distribution says it should not be: the top
-- 1,000 names account for 78.6% of all births and the top 5,000 for 93.5%, so
-- below about rank 5,000 ranking one name above another is noise. Popularity is
-- not a dial here. It is a way to mix names the user will recognise with names
-- they will not.
--
-- So this serves a blend. Seven of every ten names come from a band of the most
-- popular names under the current filters, two from a wider band, one from wider
-- still — "yes, of course", "oh, I used to know an Aditi", and "Rei? how do you
-- pronounce that?" in one batch.
--
-- The bands roll. Their offset is how many names this user has already actioned
-- within these filters, so after 500 approvals and rejections the top band is
-- ranks 500-1000 and what used to be unfamiliar has become the familiar tier. No
-- state is stored for this: the offset is counted from user_given_names_states on
-- every call, so it is always correct and never needs migrating. Anchoring on the
-- most popular un-actioned name instead sounds equivalent and is not — selection
-- inside a band is random, so the single name at the top of it is picked about
-- 1.4% of the time and the anchor would sit still for dozens of batches.
--
-- There is no floor. The bands keep rolling as long as unactioned names exist, and
-- the backfill below reaches past the widest band rather than returning short.
--
-- Under 300 candidates the bands are switched off. A user who filters to Irish
-- names of the 1930s has a pool of 84 spread thinly across the whole rank range;
-- tiering that is machinery doing no work, and they will see all of it regardless.
--
-- Rank comes from given_name_popularity_by_decade when decades are filtered and
-- from given_name_popularity_overall (045) when they are not. Same columns, so it
-- is one query against a different table rather than two query paths. Across
-- several decades a name takes its best rank among them, which is not the same as
-- ranking by their summed occurrences — Diana is 52nd by her best decade and 133rd
-- by the sum of 1920-40 — but both land her in the same tier, and the tier is all
-- the user ever sees.
--
-- p_popularity_percentile is gone. See ticket [095] for removing what remains of
-- it from the backend and the generated client; this function dropping it is what
-- that ticket waits on.
--
-- Each candidate also carries its etymology. See ticket [096].
--
-- The card needs a name's meanings and languages the moment it is shown, and a
-- second request per card is a round trip for data that is already joined here.
-- So every row carries out_etymology:
--
--   {
--     meanings:  [{ id, text, language: { id, label, flag } | null }],
--     languages: [{ id, label, flag }],
--     cultures:  [{ id, label }]
--   } | null
--
-- It is built only for the rows the query finally returns, never for the pool, so
-- the cost is three indexed lookups per served name.
--
-- Meanings come from meanings and given_name_meaning_bridge. A bridge row is unique
-- per source and extraction method, so the same meaning in the same language can
-- appear more than once; it is shown once. A meaning with no language gets a null
-- language rather than no key.
--
-- cultures has no flag column, so a culture carries no flag.
--
-- etymology is null only when a name has none of the three. When it is present all
-- three arrays are present, empty where there is nothing to show.
--
-- Also dropped here:
--   get_etymology (028) — read given_name_meaning, which nothing should read now.
--     Its route is retired; the data arrives with the candidate.
--   get_name_candidates_meta (024) — the only thing still returning a popularity
--     percentile. See ticket [095].

DROP FUNCTION IF EXISTS get_etymology(INT);

DROP FUNCTION IF EXISTS get_name_candidates_meta(
  INT,
  numeric,
  INT[],
  INT[],
  INT[],
  INT[],
  INT
);

DROP FUNCTION IF EXISTS get_name_candidates(
  INT,
  numeric,
  INT[],
  INT[],
  INT[],
  INT[],
  INT,
  INT[]
);

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
  -- these one at a time.
  SELECT
    f.bid,
    f.given_name,
    CASE
      WHEN e.meanings IS NULL AND e.languages IS NULL AND e.cultures IS NULL THEN NULL
      ELSE json_build_object(
        'meanings',  COALESCE(e.meanings,  '[]'::json),
        'languages', COALESCE(e.languages, '[]'::json),
        'cultures',  COALESCE(e.cultures,  '[]'::json)
      )
    END
  FROM filled f
  CROSS JOIN LATERAL (
    SELECT
      (
        SELECT json_agg(
          json_build_object(
            'id', m.id,
            'text', m.text,
            'language', CASE
              WHEN l.id IS NULL THEN NULL
              ELSE json_build_object('id', l.id, 'label', l.label, 'flag', l.flag)
            END
          )
          ORDER BY m.text, l.label
        )
        FROM (
          SELECT DISTINCT gnmb.meaning_id, gnmb.language_id
          FROM given_name_meaning_bridge gnmb
          WHERE gnmb.given_name_id = f.given_name_id
        ) mb
        JOIN meanings m
          ON m.id = mb.meaning_id
        LEFT JOIN languages l
          ON l.id = mb.language_id
      ) AS meanings,

      (
        SELECT json_agg(
          json_build_object('id', l.id, 'label', l.label, 'flag', l.flag)
          ORDER BY l.label
        )
        FROM given_name_language_bridge gnlb
        JOIN languages l
          ON l.id = gnlb.language_id
        WHERE gnlb.given_name_id = f.given_name_id
      ) AS languages,

      (
        SELECT json_agg(
          json_build_object('id', c.id, 'label', c.label)
          ORDER BY c.label
        )
        FROM given_name_culture_bridge gncb
        JOIN cultures c
          ON c.id = gncb.culture_id
        WHERE gncb.given_name_id = f.given_name_id
      ) AS cultures
  ) e
  ORDER BY random();

END;
$$ LANGUAGE plpgsql;
