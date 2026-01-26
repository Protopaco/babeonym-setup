
CREATE OR REPLACE FUNCTION update_user_settings (
    p_user_id INT,
    p_theme theme DEFAULT NULL,
    p_sur_name TEXT DEFAULT NULL
) RETURNS TABLE (
    user_id INT,
    theme theme,
    sur_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    UPDATE user_settings
    SET
        theme = COALESCE(p_theme, theme),
        sur_name = COALESCE(p_sur_name, sur_name)
    WHERE user_id = p_user_id
    RETURNING user_id, theme, sur_name;
END;