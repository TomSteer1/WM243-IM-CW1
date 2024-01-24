-- Create Users table
CREATE TABLE adminSchema.Users (
    ID SERIAL PRIMARY KEY,
    Username VARCHAR(255) UNIQUE NOT NULL,
    Hash VARCHAR(255) NOT NULL,
    Salt VARCHAR(255) NOT NULL,
    Permissions SMALLINT NOT NULL DEFAULT 1,
    Balance NUMERIC(10, 2) DEFAULT 0,
    Token VARCHAR(255),
    lastLogin TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE adminSchema.remove_inactive_users()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM adminSchema.Users where lastLogin < CURRENT_TIMESTAMP - NTERVAL '6 months';
END;
$$;