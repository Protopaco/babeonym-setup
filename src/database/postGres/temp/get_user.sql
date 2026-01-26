
CREATE OR REPLACE FUNCTION get_user(
    p_user_id INT
)
RETURNS TABLE (
    id INT,
    auth_provider auth_provider,
    email TEXT,
    user_name TEXT,
    theme theme,
    sur_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.auth_provider,
        u.email,
        u.user_name,
        us.theme,
        us.sur_name
    FROM users u
    LEFT JOIN user_settings us ON u.id = us.user_id
    WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql;    
