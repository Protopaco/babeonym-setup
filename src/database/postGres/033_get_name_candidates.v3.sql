-- Revises get_name_candidates (from 031) and get_name_candidates_meta (from
-- 024) to take gender ids instead of enum values, so every filter the client
-- sends is a list of ids from the same reference endpoint.
--
-- The ids are resolved against the genders table added in 032 before the query
-- runs. Everything downstream is unchanged: gender is still derived from
-- gender_difference and female_share, and still compared against the same enum
-- values.
--
-- Ids that resolve to nothing match nothing, rather than being treated as an
-- absent filter. A silently ignored filter is the harder bug to notice.
--
-- Both prior signatures are dropped explicitly. Changing a parameter type
-- creates an overload rather than replacing the function, and existing callers
-- would keep resolving to the old one.

DROP FUNCTION IF EXISTS get_name_candidates(
  INT,
  numeric,
  gender[],
  INT[],
  INT[],
  INT[],
  INT
);

DROP FUNCTION IF EXISTS get_name_candidates(
  INT,
  numeric,
  gender[],
  INT[],
  INT[],
  INT[],
  INT,
  INT[]
);

CREATE OR REPLACE FUNCTION get_name_candidates(
  p_user_id INT,
  p_popularity_percentile numeric DEFAULT 1.0,
  p_gender_ids INT[] DEFAULT NULL,
  p_decade_ids INT[] DEFAULT NULL,
  p_language_ids INT[] DEFAULT NULL,
  p_culture_ids INT[] DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_exclude_bridge_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  out_given_custom_name_bridge_id INT,
  out_given_name TEXT
) AS $$
DECLARE
  v_genders gender[];
BEGIN
  IF p_gender_ids IS NOT NULL THEN
    SELECT array_agg(g.value)
    INTO v_genders
    FROM genders g
    WHERE g.id = ANY(p_gender_ids);
  END IF;

  RETURN QUERY
  WITH params AS (
    SELECT
      p_user_id AS user_id,
      LEAST(1, GREATEST(0, COALESCE(p_popularity_percentile, 1.0))) AS x,
      GREATEST(1, COALESCE(NULLIF(p_limit, 0), 50)) AS lim
  ),

  candidates_raw AS (
    SELECT
      b.id AS given_custom_name_bridge_id,
      gnpbd.percentile,
      gn.given_name,

      CASE
        WHEN gnpbd.gender_difference IS NULL THEN NULL::gender
        WHEN gnpbd.gender_difference <= 0.40 THEN 'neutral'::gender
        WHEN gnpbd.female_share > 0.50 THEN 'female'::gender
        ELSE 'male'::gender
      END AS derived_gender

    FROM given_name_popularity_by_decade gnpbd
    JOIN given_names gn
      ON gn.id = gnpbd.given_name_id
    JOIN given_custom_name_bridge b
      ON b.given_name_id = gn.id

    WHERE
      (p_decade_ids IS NULL OR gnpbd.decade_id = ANY(p_decade_ids))

      AND (
        p_gender_ids IS NULL
        OR (
          CASE
            WHEN gnpbd.gender_difference IS NULL THEN NULL::gender
            WHEN gnpbd.gender_difference <= 0.40 THEN 'neutral'::gender
            WHEN gnpbd.female_share > 0.50 THEN 'female'::gender
            ELSE 'male'::gender
          END
        ) = ANY(v_genders)
      )

      AND (
        p_exclude_bridge_ids IS NULL
        OR b.id <> ALL(p_exclude_bridge_ids)
      )

      AND NOT EXISTS (
        SELECT 1
        FROM user_given_names_states u
        WHERE u.user_id = p_user_id
          AND u.given_custom_name_bridge_id = b.id
          AND u.state IN ('rejected', 'approved')
      )

      AND NOT EXISTS (
        SELECT 1
        FROM user_given_names_states u2
        WHERE u2.user_id = p_user_id
          AND u2.given_custom_name_bridge_id = b.id
          AND u2.state = 'snoozed'
          AND u2.date_created > NOW() - INTERVAL '24 hours'
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
  ),

  candidates AS (
    SELECT given_custom_name_bridge_id, given_name, percentile
    FROM (
      SELECT
        cr.*,
        ROW_NUMBER() OVER (
          PARTITION BY cr.given_custom_name_bridge_id
          ORDER BY ABS(cr.percentile - (SELECT x FROM params)) ASC
        ) AS rn
      FROM candidates_raw cr
    ) t
    WHERE rn = 1
  ),

  -- 1.0 is the last rung: clamped against [0, 1] it covers the whole range from
  -- any target, so the ladder can always reach every remaining candidate.
  bands AS (
    SELECT unnest(ARRAY[0.02, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 1.00])::numeric AS w
  ),

  band_counts AS (
    SELECT b.w, count(*) AS n
    FROM bands b
    CROSS JOIN params p
    JOIN candidates c
      ON c.percentile BETWEEN GREATEST(0, p.x - b.w) AND LEAST(1, p.x + b.w)
    GROUP BY b.w
  ),

  chosen_band AS (
    (SELECT w
     FROM band_counts
     CROSS JOIN params p
     WHERE n >= p.lim
     ORDER BY w
     LIMIT 1)
    UNION ALL
    (SELECT max(w)
     FROM band_counts
     WHERE NOT EXISTS (
       SELECT 1
       FROM band_counts
       CROSS JOIN params p
       WHERE n >= p.lim
     ))
  ),

  results AS (
    SELECT
      c.given_custom_name_bridge_id,
      c.given_name
    FROM candidates c
    CROSS JOIN params p
    CROSS JOIN (SELECT w FROM chosen_band LIMIT 1) cb
    WHERE c.percentile BETWEEN GREATEST(0, p.x - cb.w) AND LEAST(1, p.x + cb.w)
    ORDER BY c.percentile DESC, random()
    LIMIT (SELECT lim FROM params)
  )

  SELECT
    r.given_custom_name_bridge_id AS out_given_custom_name_bridge_id,
    r.given_name                 AS out_given_name
  FROM results r;

END;
$$ LANGUAGE plpgsql;


-- The meta variant takes the same gender parameter, so it moves with it. It is
-- off the live path today, but leaving it on the old signature would mean the
-- one backend call site can only satisfy one of the two functions.

DROP FUNCTION IF EXISTS get_name_candidates_meta(
  INT,
  numeric,
  gender[],
  INT[],
  INT[],
  INT[],
  INT
);

CREATE OR REPLACE FUNCTION get_name_candidates_meta(
  p_user_id INT,
  p_popularity_percentile numeric DEFAULT 1.0,
  p_gender_ids INT[] DEFAULT NULL,
  p_decade_ids INT[] DEFAULT NULL,
  p_language_ids INT[] DEFAULT NULL,
  p_culture_ids INT[] DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  out_given_custom_name_bridge_id INT,
  out_given_name TEXT,
  out_percentile numeric,
  out_gender gender
) AS $$
DECLARE
  v_genders gender[];
BEGIN
  IF p_gender_ids IS NOT NULL THEN
    SELECT array_agg(g.value)
    INTO v_genders
    FROM genders g
    WHERE g.id = ANY(p_gender_ids);
  END IF;

  RETURN QUERY
  WITH params AS (
    SELECT
      p_user_id AS user_id,
      LEAST(1, GREATEST(0, COALESCE(p_popularity_percentile, 1.0))) AS x,
      GREATEST(1, COALESCE(NULLIF(p_limit, 0), 50)) AS lim
  ),

  candidates_raw AS (
    SELECT
      b.id AS given_custom_name_bridge_id,
      gnpbd.percentile,
      gn.given_name,

      CASE
        WHEN gnpbd.gender_difference IS NULL THEN NULL::gender
        WHEN gnpbd.gender_difference <= 0.40 THEN 'neutral'::gender
        WHEN gnpbd.female_share > 0.50 THEN 'female'::gender
        ELSE 'male'::gender
      END AS derived_gender

    FROM given_name_popularity_by_decade gnpbd
    JOIN given_names gn
      ON gn.id = gnpbd.given_name_id
    JOIN given_custom_name_bridge b
      ON b.given_name_id = gn.id

    WHERE
      (p_decade_ids IS NULL OR gnpbd.decade_id = ANY(p_decade_ids))

      AND (
        p_gender_ids IS NULL
        OR (
          CASE
            WHEN gnpbd.gender_difference IS NULL THEN NULL::gender
            WHEN gnpbd.gender_difference <= 0.40 THEN 'neutral'::gender
            WHEN gnpbd.female_share > 0.50 THEN 'female'::gender
            ELSE 'male'::gender
          END
        ) = ANY(v_genders)
      )

      AND NOT EXISTS (
        SELECT 1
        FROM user_given_names_states u
        WHERE u.user_id = p_user_id
          AND u.given_custom_name_bridge_id = b.id
          AND u.state IN ('rejected', 'approved')
      )

      AND NOT EXISTS (
        SELECT 1
        FROM user_given_names_states u2
        WHERE u2.user_id = p_user_id
          AND u2.given_custom_name_bridge_id = b.id
          AND u2.state = 'snoozed'
          AND u2.date_created > NOW() - INTERVAL '24 hours'
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
  ),

  candidates AS (
    SELECT given_custom_name_bridge_id, given_name, percentile, derived_gender
    FROM (
      SELECT
        cr.*,
        ROW_NUMBER() OVER (
          PARTITION BY cr.given_custom_name_bridge_id
          ORDER BY ABS(cr.percentile - (SELECT x FROM params)) ASC
        ) AS rn
      FROM candidates_raw cr
    ) t
    WHERE rn = 1
  ),

  bands AS (
    SELECT unnest(ARRAY[0.02, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 1.00])::numeric AS w
  ),

  band_counts AS (
    SELECT b.w, count(*) AS n
    FROM bands b
    CROSS JOIN params p
    JOIN candidates c
      ON c.percentile BETWEEN GREATEST(0, p.x - b.w) AND LEAST(1, p.x + b.w)
    GROUP BY b.w
  ),

  chosen_band AS (
    (SELECT w
     FROM band_counts
     CROSS JOIN params p
     WHERE n >= p.lim
     ORDER BY w
     LIMIT 1)
    UNION ALL
    (SELECT max(w)
     FROM band_counts
     WHERE NOT EXISTS (
       SELECT 1
       FROM band_counts
       CROSS JOIN params p
       WHERE n >= p.lim
     ))
  ),

  results AS (
    SELECT
      c.given_custom_name_bridge_id,
      c.given_name,
      c.percentile,
      c.derived_gender
    FROM candidates c
    CROSS JOIN params p
    CROSS JOIN (SELECT w FROM chosen_band LIMIT 1) cb
    WHERE c.percentile BETWEEN GREATEST(0, p.x - cb.w) AND LEAST(1, p.x + cb.w)
    ORDER BY random()
    LIMIT (SELECT lim FROM params)
  )

  SELECT
    r.given_custom_name_bridge_id AS out_given_custom_name_bridge_id,
    r.given_name                 AS out_given_name,
    r.percentile                 AS out_percentile,
    r.derived_gender             AS out_gender
  FROM results r;

END;
$$ LANGUAGE plpgsql;
