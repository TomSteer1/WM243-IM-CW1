CREATE OR REPLACE FUNCTION userSchema.manager_get_logs(
	p_token VARCHAR(255),
    p_logtype INT DEFAULT -1
)
RETURNS TABLE (
    id int,
    username VARCHAR,
    logtype VARCHAR,
    message text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    if p_logtype = -1 then
        return query select * from adminSchema.list_logs;
    end if;

    return query select * from adminSchema.list_logs where list_logs.logtype = (select logtypes.logtype from adminSchema.logtypes where logtypes.id = p_logtype);
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_get_payments(
	p_token VARCHAR(255),
    p_req_user_id INT DEFAULT -1
)
RETURNS TABLE (
    id uuid,
    username VARCHAR,
    payment_amount NUMERIC,
    description VARCHAR,
    status VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    if p_req_user_id = -1 then
        return query select 
            payment_id,
            list_payments.username,
            list_payments.amount,list_payments.description,list_payments.status_message from adminSchema.list_payments;
    end if;

    return query select payment_id,list_payments.username,list_payments.amount,list_payments.description,list_payments.status_message from adminSchema.list_payments where user_id = p_req_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_approve_payment(
	p_token VARCHAR(255),
    p_payment_id uuid
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.list_payments where payment_id=p_payment_id;

    if v_count != 1 then 
        call adminSchema.log(12,'Payment ID not found');
        return 'Payment ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    if (select status_message from adminSchema.list_payments where payment_id=p_payment_id)= 'Cancelled' then
        if (select amount from adminSchema.list_payments where payment_id=p_payment_id) > (select balance from adminSchema.users where id=(select user_id from adminSchema.list_payments where payment_id=p_payment_id)) then
            call adminSchema.log(12,'Lack of funds',p_user_id);
            return 'The payment was been cancelled and the account does not have sufficient funds to reoopen.';
        end if;
        update adminSchema.users set balance = balance - (select amount from adminSchema.list_payments where payment_id=p_payment_id) where id = (select user_id from adminSchema.list_payments where payment_id=p_payment_id);
    end if;

    update adminSchema.payments set status = (select id from adminSchema.statuses where message = 'Complete') where id = p_payment_id;
    call adminSchema.log(13,'Payment completed',p_user_id);
    return true;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_cancel_payment(
	p_token VARCHAR(255),
    p_payment_id uuid
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
    v_uuid uuid;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.list_payments where payment_id=p_payment_id;

    if v_count != 1 then 
        call adminSchema.log(12,'Payment ID not found');
        return 'Payment ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    if (select status_message from adminSchema.list_payments where payment_id=p_payment_id) = 'Cancelled' then
        call adminSchema.log(12,'Payment already cancelled',p_user_id);
        return 'Payment already cancelled';
    end if;
    update adminSchema.payments set status = (select id from adminSchema.statuses where message = 'Cancelled') where id = p_payment_id;
    update adminSchema.users set balance = balance + (select amount from adminSchema.list_payments where payment_id=p_payment_id) where id = (select user_id from adminSchema.list_payments where payment_id=p_payment_id);
    call adminSchema.log(13,'Payment completed',p_user_id);
    return true;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_create_item(
    p_token VARCHAR(255),
    p_name VARCHAR(255),
    p_price NUMERIC,
    p_game_id INT,
    p_purchasable BOOLEAN DEFAULT true
)
RETURNS TABLE (
    id INT,
    name VARCHAR,
    price NUMERIC,
    game_id INT,
    purchasable BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
    v_item_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.games where games.id = p_game_id;

    if v_count != 1 then 
        call adminSchema.log(24,'Game ID not found');
        RAISE EXCEPTION 'Game ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    -- Check if item name exists
    if (select count(*) from adminSchema.items where items.name = p_name) > 0 then
        call adminSchema.log(24,'Item name already exists');
        RAISE EXCEPTION 'Item name already exists';
    end if;

    -- Create item
    insert into adminSchema.items (name,price,gameid,purchasable) values (p_name,p_price,p_game_id,p_purchasable) returning items.id into v_item_id;
    call adminSchema.log(25,'Item created',p_user_id);
    return query select items.id,items.name,items.price,items.gameid,items.purchasable from adminSchema.items where items.id = v_item_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_create_game(
    p_token VARCHAR(255),
    p_name VARCHAR(255),
    p_price NUMERIC
)
RETURNS TABLE (
    id INT,
    name VARCHAR,
    price NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
    v_game_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.games where games.name = p_name;

    if v_count > 0 then 
        call adminSchema.log(26,'Game name already exists');
        RAISE EXCEPTION 'Game name already exists';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    -- Create game
    insert into adminSchema.games (name,price) values (p_name,p_price) returning games.id into v_game_id;
    call adminSchema.log(27,'Game created',p_user_id);
    return query select games.id,games.name,games.price from adminSchema.games where games.id = v_game_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_delete_item(
    p_token VARCHAR(255),
    p_item_id INT
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.items where items.id = p_item_id;

    if v_count != 1 then 
        call adminSchema.log(28,'Item ID not found');
        return 'Item ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    -- Delete item
    delete from adminSchema.items where items.id = p_item_id;
    call adminSchema.log(29,'Item deleted',p_user_id);
    return true;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_delete_game(
    p_token VARCHAR(255),
    p_game_id INT
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.games where games.id = p_game_id;

    if v_count != 1 then 
        call adminSchema.log(30,'Game ID not found');
        return 'Game ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    -- Delete game
    delete from adminSchema.games where games.id = p_game_id;
    call adminSchema.log(31,'Game deleted',p_user_id);
    return true;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_mimic_user(
    p_token VARCHAR(255),
    p_username VARCHAR(255)
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.users where users.username = p_username;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(11,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    if v_count != 1 then 
        call adminSchema.log(32,'User ID not found',p_user_id);
        return 'User ID not found';
    end if;

    -- Mimic user
    call adminSchema.log(33,'User mimiced',p_user_id);
    return (select token from adminSchema.users where users.username = p_username);
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_ban_user(
    p_token VARCHAR(255),
    p_username VARCHAR(255)
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.users where users.username = p_username;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(34,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(34,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    if v_count != 1 then 
        call adminSchema.log(34,'User ID not found',p_user_id);
        return 'User ID not found';
    end if;

    -- Ban user
    update adminSchema.users set permissions = 0 where users.username = p_username;
    call adminSchema.log(35,'User banned',p_user_id);
    return true;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.manager_unban_user(
    p_token VARCHAR(255),
    p_username VARCHAR(255)
)
RETURNS VARCHAR(255)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    v_count INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    select count(*) into v_count from adminSchema.users where users.username = p_username;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(34,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Manager') = false then    
        call adminSchema.log(34,'Access denied',p_user_id);
        return 'Access denied';
    end if;

    if v_count != 1 then 
        call adminSchema.log(34,'User ID not found',p_user_id);
        return 'User ID not found';
    end if;

    -- Unban user
    update adminSchema.users set permissions = 1 where users.username = p_username;
    call adminSchema.log(35,'User unbanned',p_user_id);
    return true;
END;
$$;