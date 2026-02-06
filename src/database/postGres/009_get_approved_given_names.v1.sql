CREATE OR REPLACE FUNCTION get_approved_given_names(p_user_id INT)
RETURNS TABLE (
  out_given_custom_name_bridge_id INT,
  out_rating DOUBLE PRECISION,
  out_given_name TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    gcnb.id AS out_given_custom_name_bridge_id,
    COALESCE(gnr.rating::double precision, 1000.0::double precision) AS out_rating,
    COALESCE(gn.given_name, cgn.given_name) AS out_given_name
  FROM user_given_names_states ugns
  JOIN given_custom_name_bridge gcnb
    ON gcnb.id = ugns.given_custom_name_bridge_id
  LEFT JOIN given_names gn
    ON gn.id = gcnb.given_name_id
  LEFT JOIN custom_given_names cgn
    ON cgn.id = gcnb.custom_given_name_id
  LEFT JOIN given_name_ratings gnr
    ON gnr.given_custom_name_bridge_id = gcnb.id
   AND gnr.user_id = p_user_id
  WHERE ugns.user_id = p_user_id
    AND ugns.state = 'approved'
  ORDER BY out_rating DESC, out_given_name ASC;
END;
$$;
