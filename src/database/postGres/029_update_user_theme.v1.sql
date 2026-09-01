DROP FUNCTION IF EXISTS update_user_theme(p_user_id INT, p_theme theme);

CREATE OR REPLACE FUNCTION update_user_theme (
    p_user_id INT,
    p_theme theme
) RETURNS TABLE (
    out_user_id INT,
    out_theme theme
) AS $$
BEGIN
    RETURN QUERY
    UPDATE user_settings
    SET theme = p_theme
    WHERE user_id = p_user_id
    RETURNING user_id, theme;
END;
$$ LANGUAGE plpgsql;
