DROP FUNCTION IF EXISTS get_reference_languages();

CREATE OR REPLACE FUNCTION get_reference_languages()
RETURNS TABLE (
  out_id INT,
  out_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, name
  FROM languages
  ORDER BY name;
END;
$$ LANGUAGE plpgsql;    