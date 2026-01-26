CREATE OR REPLACE FUNCTION reset_user(
    p_user_id INT
)
RETURNS VOID AS $$
BEGIN
    -- Clear user-specific state
    DELETE FROM user_given_names_states
    WHERE user_id = p_user_id;

    -- Clear ratings
    DELETE FROM given_name_ratings
    WHERE user_id = p_user_id;

    -- Delete bridge rows for this user's custom names
    DELETE FROM given_custom_name_bridge
    WHERE custom_given_name_id IN (
        SELECT id
        FROM custom_given_names
        WHERE user_id = p_user_id
    );

    -- Delete custom names
    DELETE FROM custom_given_names
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;
