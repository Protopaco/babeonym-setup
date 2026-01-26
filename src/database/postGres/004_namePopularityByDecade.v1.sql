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
ranked AS (
  SELECT
    *,
    RANK() OVER (PARTITION BY gender, decade_id ORDER BY total_occ DESC) AS rnk,
    COUNT(*) OVER (PARTITION BY gender, decade_id) AS n
  FROM agg
)
INSERT INTO given_name_popularity_by_decade (
  given_name_id, gender, decade_id, rank, percentile, date_created
)
SELECT
  given_name_id,
  gender,
  decade_id,
  rnk AS rank,
  CASE
    WHEN n = 1 THEN 1::numeric
    ELSE 1::numeric - ((rnk - 1)::numeric / (n - 1)::numeric)
  END AS percentile,
  CURRENT_TIMESTAMP
FROM ranked;
