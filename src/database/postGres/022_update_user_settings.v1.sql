DROP FUNCTION IF EXISTS update_user_settings(p_user_id INT, p_theme theme, p_sur_name TEXT);
DROP FUNCTION IF EXISTS update_user_settings(p_user_id INT, p_sur_name TEXT);

CREATE OR REPLACE FUNCTION update_user_settings (
    p_user_id INT,
    p_sur_name TEXT DEFAULT NULL
) RETURNS TABLE (
    out_user_id INT,
    out_theme theme,
    out_sur_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    UPDATE user_settings
    SET
        sur_name = COALESCE(p_sur_name, sur_name)
    WHERE user_id = p_user_id
    RETURNING user_id, theme, sur_name;
END;
$$ LANGUAGE plpgsql;
