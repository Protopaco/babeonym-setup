DROP FUNCTION IF EXISTS add_custom_given_name(p_user_id INT, p_custom_given_name
 TEXT);

CREATE OR REPLACE FUNCTION add_custom_given_name(
    p_user_id INT,
    p_custom_given_name TEXT
)
RETURNS VOID AS $$
DECLARE
  v_given_name_id INT;
  v_custom_id INT;
  v_bridge_id INT;
BEGIN
  -- 1) Prefer an existing canonical name over creating a custom one.
  --
  -- Without this, approving "John" as a custom name leaves canonical "John"
  -- untouched on its own bridge row. get_name_candidates excludes candidates by
  -- bridge id, so the generator would go on offering a name already sitting in
  -- the user's approved list, and approving it again would put two Johns in the
  -- list where compare could pair them against each other.
  --
  -- Matched case-insensitively and the canonical spelling wins, so JOHN and john
  -- both land on John. Deliberately exact otherwise: Myke must not match Mike.
  --
  -- given_name is unique case-sensitively, so LOWER() could in principle match
  -- more than one row. Ordered so the result is at least deterministic.
  SELECT gn.id INTO v_given_name_id
  FROM given_names gn
  WHERE LOWER(gn.given_name) = LOWER(p_custom_given_name)
  ORDER BY gn.id
  LIMIT 1;

  IF v_given_name_id IS NOT NULL THEN
    -- Canonical names are bridged ahead of time by seed_given_custom_name_bridge,
    -- so this row exists and there is nothing to insert.
    SELECT id INTO v_bridge_id
    FROM given_custom_name_bridge
    WHERE given_name_id = v_given_name_id;
  ELSE
    -- 2) No canonical match, so find or insert the custom name
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

    -- 3) Find or insert the bridge row
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
  END IF;

  -- 4) Upsert user state to 'approved'
  --
  -- On the canonical path this can overwrite an earlier 'rejected': typing a
  -- name out is a stronger signal than having swiped past it.
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
