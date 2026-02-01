DROP FUNCTION IF EXISTS get_reference_cultures();
CREATE OR REPLACE FUNCTION get_reference_cultures()
RETURNS TABLE (
  out_id INT,
  out_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, name
  FROM cultures
  ORDER BY name;
END;
$$ LANGUAGE plpgsql;    
