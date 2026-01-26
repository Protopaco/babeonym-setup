
CREATE OR REPLACE FUNCTION get_reference_cultures()
RETURNS TABLE (
  id INT,
  name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, name
  FROM cultures
  ORDER BY name;
END;
$$ LANGUAGE plpgsql;    
