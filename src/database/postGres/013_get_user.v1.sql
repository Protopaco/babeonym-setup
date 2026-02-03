DROP FUNCTION IF EXISTS get_user(
    p_user_id INT
);
CREATE OR REPLACE FUNCTION get_user(
    p_user_id INT
)
RETURNS TABLE (
    out_id INT,
    out_auth_provider auth_provider,
    out_email TEXT,
    out_user_name TEXT,
    out_theme theme,
    out_sur_name TEXT
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
