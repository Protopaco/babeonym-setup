
CREATE OR REPLACE FUNCTION reset_user(
    p_user_id INT
)
RETURNS VOID AS $$
BEGIN

    DELETE FROM given_name_ratings 
    WHERE user_id = p_user_id;

    DELETE FROM given_custom_name_bridge WHERE id IN (
        SELECT gcnb.id
        FROM given_custom_name_bridge gcnb
        JOIN custom_given_names cgn ON gcnb.custom_given_name_id = cgn.id
        WHERE cgn.user_id = p_user_id
    );

    DELETE FROM custom_given_names 
    WHERE user_id = p_user_id;

    DELETE FROM user_given_names_states 
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;