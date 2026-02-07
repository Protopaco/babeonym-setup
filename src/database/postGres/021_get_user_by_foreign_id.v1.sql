
DROP FUNCTION IF EXISTS get_user_by_foreign_id( 
    p_foreign_id TEXT, 
    p_auth_provider auth_provider 
);

CREATE OR REPLACE FUNCTION get_user_by_foreign_id(
    p_foreign_id TEXT,
    p_auth_provider auth_provider
) RETURNS TABLE (
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
    WHERE u.foreign_id = p_foreign_id
    AND u.auth_provider = p_auth_provider;
END;
$$ LANGUAGE plpgsql;
