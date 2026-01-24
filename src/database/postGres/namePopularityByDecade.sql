-- Ensure decades exist
INSERT INTO decades (decade, label)
SELECT DISTINCT 
  (year / 10) * 10,
  (year / 10) * 10 || 's'
FROM given_name_occurrences
ON CONFLICT (decade) DO NOTHING;

-- Clear and recalculate popularity
TRUNCATE TABLE given_name_popularity_by_decade;

INSERT INTO given_name_popularity_by_decade (
  given_name_id, gender, decade_id, rank, date_created
)
SELECT
  given_name_id,
  gender,
  d.id AS decade_id,
  RANK() OVER (
    PARTITION BY gender, d.id
    ORDER BY SUM(occurrences) DESC
  ) AS rank,
  CURRENT_TIMESTAMP
FROM given_name_occurrences occ
JOIN decades d ON d.decade = (occ.year / 10) * 10
GROUP BY given_name_id, gender, d.id;