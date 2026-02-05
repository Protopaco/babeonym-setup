CREATE OR REPLACE FUNCTION add_custom_given_name(
    p_user_id INT,
    p_custom_given_name TEXT
)
RETURNS VOID AS $$
DECLARE
  v_custom_id INT;
  v_bridge_id INT;
BEGIN
  -- 1) Insert custom name (still safe to upsert here if you want)
  INSERT INTO custom_given_names (user_id, given_name, date_created)
  VALUES (p_user_id, p_custom_given_name, NOW())
  ON CONFLICT (user_id, given_name)
  DO UPDATE SET given_name = EXCLUDED.given_name
  RETURNING id INTO v_custom_id;

  -- 2) Insert bridge row (no conflict handling)
  INSERT INTO given_custom_name_bridge (custom_given_name_id)
  VALUES (v_custom_id)
  RETURNING id INTO v_bridge_id;

  -- 3) Insert / update user state
  INSERT INTO user_given_names_states (
    user_id,
    given_custom_name_bridge_id,
    state,
    date_updated
  )
  VALUES (
    p_user_id,
    v_bridge_id,
    'approved'::given_name_state,
    NOW()
  )
  ON CONFLICT (user_id, given_custom_name_bridge_id)
  DO UPDATE SET
    state = EXCLUDED.state,
    date_updated = NOW();
END;
$$ LANGUAGE plpgsql;
