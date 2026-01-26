

CREATE OR REPLACE FUNCTION update_user_last_active(
    p_user_id INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET last_active = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;    