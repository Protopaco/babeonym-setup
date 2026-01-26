CREATE OR REPLACE FUNCTION get_reference_decades()
RETURNS TABLE (
  id INT,
  decade INT,
  label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, decade, label
  FROM decades
  ORDER BY decade;
END;
$$ LANGUAGE plpgsql;
