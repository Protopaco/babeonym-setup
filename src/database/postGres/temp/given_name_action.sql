CREATE OR REPLACE FUNCTION given_name_action(
  p_user_id INT,
  p_given_custom_name_bridge_id INT,
  p_given_name_state given_name_state
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO user_given_names_states (user_id, given_custom_name_bridge_id, state)
  VALUES (p_user_id, p_given_custom_name_bridge_id, p_given_name_state)
  ON CONFLICT (user_id, given_custom_name_bridge_id)
  DO UPDATE SET
    state = EXCLUDED.state
END;
$$ LANGUAGE plpgsql;
