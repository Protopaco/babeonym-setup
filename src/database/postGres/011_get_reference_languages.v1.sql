-- SUPERSEDED BY 034_get_name_filters.v1.sql, and dropped by 035.
-- Kept for history. Do not run: nothing consumes this function any more.

DROP FUNCTION IF EXISTS get_reference_languages();

CREATE OR REPLACE FUNCTION get_reference_languages()
RETURNS TABLE (
  out_continent_id INT,
  out_continent_label TEXT,
  out_region_id INT,
  out_region_label TEXT,
  out_language_id INT,
  out_language_label TEXT,
  out_language_flag TEXT
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    c.id    AS continent_id,
    c.label AS continent_label,
    r.id    AS region_id,
    r.label AS region_label,
    l.id    AS language_id,
    l.label AS language_label,
    l.flag  AS language_flag
  FROM regions c
  JOIN regions r
    ON r.parent_id = c.id
  LEFT JOIN language_region_bridge lrb
    ON lrb.region_id = r.id
  LEFT JOIN languages l
    ON l.id = lrb.language_id
  WHERE c.parent_id IS NULL
  ORDER BY
    c.label,
    r.label,
    l.label;
$$;