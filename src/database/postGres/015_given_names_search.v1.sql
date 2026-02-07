DROP FUNCTION IF EXISTS given_names_search(
    p_user_id INT,
    p_search_text TEXT,
    p_limit INT
);

CREATE OR REPLACE FUNCTION given_names_search(
    p_user_id INT,
    p_search_text TEXT,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    out_given_custom_name_bridge_id INT,
    out_given_name TEXT,
    out_rating NUMERIC,
) AS $$
BEGIN
  RETURN QUERY
  SELECT
      gcnb.id,
      gn.given_name,
      gnr.rating
  FROM given_names gn
  JOIN given_custom_name_bridge gcnb
    ON gcnb.given_name_id = gn.id
  LEFT JOIN given_name_ratings gnr
    ON gnr.given_custom_name_bridge_id = gcnb.id
   AND gnr.user_id = p_user_id
  WHERE gn.given_name ILIKE '%' || p_search_text || '%'
    AND NOT EXISTS (
      SELECT 1
      FROM user_given_names_states ugns
      WHERE ugns.user_id = p_user_id
        AND ugns.given_custom_name_bridge_id = gcnb.id
        AND ugns.state = 'approved'
    )
  ORDER BY gn.given_name
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
