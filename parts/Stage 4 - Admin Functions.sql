CREATE OR REPLACE FUNCTION adminSchema.auth_user(
	p_token VARCHAR(255)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
	user_id INT;
	user_count INT;
BEGIN
	SELECT COUNT(*) into user_count
	FROM adminSchema.users
	WHERE token = p_token;

	IF user_count = 1 THEN
		SELECT id into user_id
		FROM adminSchema.users
		WHERE token = p_token;
		return user_id;	
	ELSE
		return -1;
	END IF;
END;
$$;

CREATE OR REPLACE FUNCTION adminSchema.check_user_id(
	user_id INT
)
RETURNS BOOL
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
	user_count INT;
BEGIN
	SELECT COUNT(*) INTO user_count
	FROM adminSchema.users
	WHERE id = user_id;
	
	IF user_count = 1 then
		return true;
	ELSE
		return false;
	END IF;
	
END;
$$;

-- CREATE OR REPLACE FUNCTION adminSchema.check_permissions(
-- 	user_id INT,
--     role_id INT
-- )
-- RETURNS BOOL
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- DECLARE
-- 	user_count INT;
-- BEGIN
-- 	SELECT COUNT(*) INTO user_count
-- 	FROM adminSchema.users
-- 	WHERE id = user_id
--         AND type = role_id;
	
-- 	IF user_count = 1 then
-- 		return true;
-- 	ELSE
-- 		return false;
-- 	END IF;
	
-- END;
-- $$;

CREATE OR REPLACE procedure adminSchema.log(
    logtype INT,
    message VARCHAR,
    userid INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO adminSchema.logs (logtype,userid,message) values (logtype,userid,message);
END;
$$;

CREATE OR REPLACE procedure adminSchema.log(
    logtype INT,
    message VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO adminSchema.logs (logtype,userid,message) values (logtype,0,message);
END;
$$;

CREATE OR REPLACE FUNCTION adminSchema.check_permissions(p_user_id int, p_permission VARCHAR) 
RETURNS boolean 
LANGUAGE plpgsql
AS $$
DECLARE
    permissions_count INT;
BEGIN
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(0,'User does not exist');
        RAISE EXCEPTION 'User does not exist';
    end if;

    SELECT COUNT(*) into permissions_count from adminSchema.permissions where permission = p_permission;

    if permissions_count != 1 then 
        call adminSchema.log(0,'Permission does not exist');
        RAISE EXCEPTION 'Permission does not exist';
    end if;

    
    return ((SELECT users.permissions from adminSchema.users where id = p_user_id) >> (SELECT Bit_no from adminSchema.permissions where permission = p_permission)) & 1 = 1;     
END;
$$;