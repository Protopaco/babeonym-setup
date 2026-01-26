CREATE OR REPLACE FUNCTION add_custom_given_name(
    p_user_id INT,
    p_custom_given_name TEXT
)
RETURNS VOID AS $$
DECLARE
  v_custom_id INT;
BEGIN
  -- 1) Upsert custom name, capture id either way
  INSERT INTO custom_given_names (user_id, given_name, date_created)
  VALUES (p_user_id, p_custom_given_name, NOW())
  ON CONFLICT (user_id, given_name)
  DO UPDATE SET given_name = EXCLUDED.given_name
  RETURNING id INTO v_custom_id;

  -- 2) Ensure bridge row exists
  INSERT INTO given_custom_name_bridge (custom_given_name_id)
  VALUES (v_custom_id)
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;
