DROP FUNCTION IF EXISTS user_action_history(INT);

CREATE OR REPLACE FUNCTION user_action_history(p_user_id INT)
RETURNS TABLE (
  out_given_name TEXT,
  out_state given_name_state,
  out_date_updated TIMESTAMP,
  out_given_custom_name_bridge_id INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(gn.given_name, cgn.given_name) AS out_given_name,
    ugns.state                           AS out_state,
    ugns.date_updated                    AS out_date_updated,
    ugns.given_custom_name_bridge_id     AS out_given_custom_name_bridge_id
  FROM user_given_names_states ugns
  JOIN given_custom_name_bridge gcb
    ON ugns.given_custom_name_bridge_id = gcb.id
  LEFT JOIN given_names gn
    ON gcb.given_name_id = gn.id
  LEFT JOIN custom_given_names cgn
    ON gcb.custom_given_name_id = cgn.id
  WHERE ugns.user_id = p_user_id
  ORDER BY ugns.date_updated DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;
