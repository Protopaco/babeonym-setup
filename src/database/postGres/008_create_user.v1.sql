DROP FUNCTION IF EXISTS create_user(
    p_foreign_id TEXT,
    p_auth_provider auth_provider,
    p_email TEXT,
    p_user_name TEXT
);
CREATE OR REPLACE FUNCTION create_user(
    p_foreign_id TEXT,
    p_auth_provider auth_provider,
    p_email TEXT,
    p_user_name TEXT
)
RETURNS TABLE (
    out_id INT,
    out_email TEXT,
    out_user_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH inserted_user AS (
        INSERT INTO users (
            foreign_id,
            auth_provider,
            email,
            user_name,
            last_active,
            date_created
        )
        VALUES (
            p_foreign_id,
            p_auth_provider,
            p_email,
            p_user_name,
            NOW(),
            NOW()
        )
        ON CONFLICT (email) DO NOTHING
        RETURNING users.id, users.email, users.user_name
    ),
    inserted_settings AS (
        INSERT INTO user_settings (
            user_id,
            theme,
            date_created,
            date_updated
        )
        SELECT
            iu.id,
            'light',
            NOW(),
            NOW()
        FROM inserted_user iu
        RETURNING user_id
    )
    SELECT
        iu.id,
        iu.email,
        iu.user_name
    FROM inserted_user iu;
END;
$$ LANGUAGE plpgsql;
