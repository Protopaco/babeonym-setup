DROP FUNCTION IF EXISTS get_reference_languages();

CREATE OR REPLACE FUNCTION get_reference_languages()
RETURNS TABLE (
  out_id INT,
  out_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, label
  FROM languages
  ORDER BY label;
END;
$$ LANGUAGE plpgsql;    