DROP FUNCTION IF EXISTS get_reference_decades();
CREATE OR REPLACE FUNCTION get_reference_decades()
RETURNS TABLE (
  out_id INT,
  out_decade INT,
  out_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, decade, label
  FROM decades
  ORDER BY decade DESC;
END;
$$ LANGUAGE plpgsql;
