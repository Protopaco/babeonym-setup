DROP FUNCTION IF EXISTS add_custom_given_name(p_user_id INT, p_custom_given_name
 TEXT);

CREATE OR REPLACE FUNCTION add_custom_given_name(
    p_user_id INT,
    p_custom_given_name TEXT
)
RETURNS VOID AS $$
DECLARE
  v_custom_id INT;
  v_bridge_id INT;
BEGIN
  -- 1) Find or insert the custom name
  INSERT INTO custom_given_names (user_id, given_name, date_created)
  VALUES (p_user_id, p_custom_given_name, NOW())
  ON CONFLICT (user_id, given_name)
  DO NOTHING
  RETURNING id INTO v_custom_id;

  IF v_custom_id IS NULL THEN
    SELECT id INTO v_custom_id
    FROM custom_given_names
    WHERE user_id = p_user_id
      AND given_name = p_custom_given_name;
  END IF;

  -- 2) Find or insert the bridge row
  INSERT INTO given_custom_name_bridge (custom_given_name_id)
  VALUES (v_custom_id)
  ON CONFLICT (custom_given_name_id)
  DO NOTHING
  RETURNING id INTO v_bridge_id;

  IF v_bridge_id IS NULL THEN
    SELECT id INTO v_bridge_id
    FROM given_custom_name_bridge
    WHERE custom_given_name_id = v_custom_id;
  END IF;

  -- 3) Upsert user state to 'approved'
  INSERT INTO user_given_names_states (
    user_id,
    given_custom_name_bridge_id,
    state,
    date_updated
  ) VALUES (
    p_user_id,
    v_bridge_id,
    'approved'::given_name_state,
    NOW()
  )
  ON CONFLICT (user_id, given_custom_name_bridge_id)
  DO UPDATE SET
    state = 'approved'::given_name_state,
    date_updated = NOW();

END;
$$ LANGUAGE plpgsql;
