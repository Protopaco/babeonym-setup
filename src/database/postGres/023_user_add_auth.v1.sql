
CREATE OR REPLACE FUNCTION user_add_auth(
    p_user_id INT,
    p_auth_provider auth_provider,
    p_foreign_id TEXT,
    p_email TEXT,
    p_user_name TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        auth_provider = p_auth_provider,
        foreign_id = p_foreign_id,
        email = p_email,
        user_name = p_user_name,
        last_active = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;    
    