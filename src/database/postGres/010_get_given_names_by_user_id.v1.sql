CREATE OR REPLACE FUNCTION get_given_names_by_user_id(
    p_user_id INT,
    p_popularity_percentile numeric,
    p_gender_ids gender[] DEFAULT NULL,
    p_decade_ids INT[] DEFAULT NULL,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    given_custom_name_bridge_id INT,
    given_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH params AS (
    SELECT
      p_user_id AS user_id,
      LEAST(1, GREATEST(0, p_popularity_percentile)) AS x,
      GREATEST(1, p_limit) AS lim
  ),

  candidates_raw AS (
    SELECT
      b.id AS given_custom_name_bridge_id,
      gnpbd.percentile,
      gn.given_name,
      gnpbd.given_name_id
    FROM given_name_popularity_by_decade gnpbd
    JOIN given_names gn ON gn.id = gnpbd.given_name_id
    JOIN given_custom_name_bridge b ON b.given_name_id = gn.id
    WHERE
      (p_decade_ids IS NULL OR gnpbd.decade_id = ANY(p_decade_ids))
      AND (p_gender_ids IS NULL OR gnpbd.gender = ANY(p_gender_ids))
      AND b.id NOT IN (
        SELECT ugns.given_custom_name_bridge_id
        FROM user_given_names_states ugns
        WHERE ugns.user_id = p_user_id
          AND ugns.state IN ('rejected', 'selected')
      )
      AND b.id NOT IN (
        SELECT ugns2.given_custom_name_bridge_id
        FROM user_given_names_states ugns2
        WHERE ugns2.user_id = p_user_id
          AND ugns2.state = 'snoozed'
          AND ugns2.date_created > NOW() - INTERVAL '24 hours'
      )
  ),

  -- One row per bridge (or per name). Here: per bridge_id (safe, since bridge is unique per name/custom)
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

  bands AS (
    SELECT unnest(ARRAY[0.02, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50])::numeric AS w
  ),

  band_counts AS (
    SELECT
      b.w,
      count(*) AS n
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
    ORDER BY random()
    LIMIT (SELECT lim FROM params)
  )

  SELECT
    r.given_custom_name_bridge_id,
    r.given_name
  FROM results r;

END;
$$ LANGUAGE plpgsql;
