-- Ensure decades exist
INSERT INTO decades (decade, label)
SELECT DISTINCT
  (year / 10) * 10,
  (year / 10) * 10 || 's'
FROM given_name_occurrences
ON CONFLICT (decade) DO NOTHING;

TRUNCATE TABLE given_name_popularity_by_decade;

WITH agg AS (
  SELECT
    occ.given_name_id,
    occ.gender,
    d.id AS decade_id,
    SUM(occ.occurrences) AS total_occ
  FROM given_name_occurrences occ
  JOIN decades d ON d.decade = (occ.year / 10) * 10
  GROUP BY occ.given_name_id, occ.gender, d.id
),

totals AS (
  SELECT
    given_name_id,
    decade_id,
    SUM(total_occ) FILTER (WHERE gender IN ('male','female')) AS mf_total,
    SUM(total_occ) FILTER (WHERE gender = 'female') AS female_total
  FROM agg
  GROUP BY given_name_id, decade_id
),

ranked AS (
  SELECT
    a.*,
    RANK() OVER (PARTITION BY a.gender, a.decade_id ORDER BY a.total_occ DESC) AS rnk,
    COUNT(*) OVER (PARTITION BY a.gender, a.decade_id) AS n
  FROM agg a
)

INSERT INTO given_name_popularity_by_decade (
  given_name_id,
  gender,
  decade_id,
  rank,
  percentile,
  total_occurrences,
  female_share,
  gender_difference,
  date_created
)
SELECT
  r.given_name_id,
  r.gender,
  r.decade_id,
  r.rnk AS rank,
  CASE
    WHEN r.n = 1 THEN 1::numeric
    ELSE 1::numeric - ((r.rnk - 1)::numeric / (r.n - 1)::numeric)
  END AS percentile,

  r.total_occ AS total_occurrences,

  (t.female_total::numeric / NULLIF(t.mf_total, 0)) AS female_share,

  ABS((t.female_total::numeric / NULLIF(t.mf_total, 0)) - 0.5) * 2 AS gender_difference,

  NOW() AS date_created
FROM ranked r
JOIN totals t
  ON t.given_name_id = r.given_name_id
 AND t.decade_id = r.decade_id;
