DROP FUNCTION IF EXISTS get_reference_cultures();

CREATE OR REPLACE FUNCTION get_reference_cultures()
RETURNS TABLE (
  out_continent_id INT,
  out_continent_label TEXT,
  out_region_id INT,
  out_region_label TEXT,
  out_culture_id INT,
  out_culture_label TEXT
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    c.id    AS out_continent_id,
    c.label AS out_continent_label,
    r.id    AS out_region_id,
    r.label AS out_region_label,
    cu.id   AS out_culture_id,
    cu.label AS out_culture_label
  FROM regions c
  JOIN regions r
    ON r.parent_id = c.id
  LEFT JOIN culture_region_bridge crb
    ON crb.region_id = r.id
  LEFT JOIN cultures cu
    ON cu.id = crb.culture_id
  WHERE c.parent_id IS NULL
  ORDER BY
    c.label,
    r.label,
    cu.label;
$$;
