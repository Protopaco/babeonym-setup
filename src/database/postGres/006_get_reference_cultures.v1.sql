DROP FUNCTION IF EXISTS get_reference_cultures();
CREATE OR REPLACE FUNCTION get_reference_cultures()
RETURNS TABLE (
  out_id INT,
  out_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, label
  FROM cultures
  ORDER BY label;
END;
$$ LANGUAGE plpgsql;    
