CREATE OR REPLACE FUNCTION get_approved_given_names(
    p_user_id INT
) 
RETURNS TABLE (
    id INT,  -- given_names.id when seeded, NULL for custom
    given_custom_name_bridge_id INT,
    given_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.given_custom_name_bridge_id,
    t.given_name
  FROM (
    -- Seeded given names
    SELECT 
      gn.id AS id,
      gcnb.id AS given_custom_name_bridge_id,
      gn.given_name AS given_name,
      COALESCE(gnr.rating, 1000.0) AS sort_rating
    FROM given_names gn
    JOIN given_custom_name_bridge gcnb
      ON gcnb.given_name_id = gn.id
    JOIN user_given_names_states ugns
      ON ugns.given_custom_name_bridge_id = gcnb.id
    LEFT JOIN given_name_ratings gnr
      ON gnr.given_custom_name_bridge_id = gcnb.id
     AND gnr.user_id = p_user_id
    WHERE ugns.user_id = p_user_id
      AND ugns.state = 'selected'

    UNION ALL

    -- Custom given names
    SELECT 
      NULL::INT AS id,
      gcnb.id AS given_custom_name_bridge_id,
      cgn.given_name AS given_name,
      COALESCE(gnr.rating, 1000.0) AS sort_rating
    FROM custom_given_names cgn
    JOIN given_custom_name_bridge gcnb
      ON gcnb.custom_given_name_id = cgn.id
    JOIN user_given_names_states ugns
      ON ugns.given_custom_name_bridge_id = gcnb.id
    LEFT JOIN given_name_ratings gnr
      ON gnr.given_custom_name_bridge_id = gcnb.id
     AND gnr.user_id = p_user_id
    WHERE ugns.user_id = p_user_id
      AND ugns.state = 'selected'
  ) t
  ORDER BY t.sort_rating DESC, t.given_name ASC;
END;
$$ LANGUAGE plpgsql;
