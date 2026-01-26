
CREATE OR REPLACE FUNCTION get_reference_languages()
RETURNS TABLE (
  id INT,
  name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, name
  FROM languages
  ORDER BY name;
END;
$$ LANGUAGE plpgsql;    