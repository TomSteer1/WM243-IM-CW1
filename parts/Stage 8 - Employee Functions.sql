CREATE OR REPLACE FUNCTION userSchema.employee_create_tournament(
    p_token VARCHAR(255),
    p_name VARCHAR(255),
    p_game_id INT,
    p_start_date TIMESTAMP,
    p_end_date TIMESTAMP
)
RETURNS TABLE (
    id INT,
    name VARCHAR,
    game_id INT,
    start_date TIMESTAMP,
    end_date TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_tournament_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Employee') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    if p_name is null or p_name = '' then
        call adminSchema.log(20,'Name cannot be null or empty');
        RAISE EXCEPTION 'Name cannot be null or empty';
    end if;

    if p_game_id is null then
        call adminSchema.log(20,'Game ID cannot be null');
        RAISE EXCEPTION 'Game ID cannot be null';
    end if;

    if p_start_date is null then
        call adminSchema.log(20,'Start date cannot be null');
        RAISE EXCEPTION 'Start date cannot be null';
    end if;

    if p_end_date is null then
        call adminSchema.log(20,'End date cannot be null');
        RAISE EXCEPTION 'End date cannot be null';
    end if;

    if p_start_date > p_end_date then
        call adminSchema.log(20,'Start date cannot be after end date');
        RAISE EXCEPTION 'Start date cannot be after end date';
    end if;

    -- Check if game exists
    if (select count(*) from adminSchema.games where games.id = p_game_id) = 0 then
        call adminSchema.log(20,'Game ID does not exist');
        RAISE EXCEPTION 'Game ID does not exist';
    end if;

    -- Check if tournament name exists
    if (select count(*) from adminSchema.tournaments where tournaments.name = p_name) > 0 then
        call adminSchema.log(20,'Tournament name already exists');
        RAISE EXCEPTION 'Tournament name already exists';
    end if;

    -- Create tournament
    insert into adminSchema.tournaments (name,gameid,starttimestamp,endtimestamp) values (p_name,p_game_id,p_start_date,p_end_date) returning tournaments.id into p_tournament_id;
    return query select tournaments.id,tournaments.name,tournaments.gameid,tournaments.starttimestamp,tournaments.endtimestamp from adminSchema.tournaments where tournaments.id = p_tournament_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.employee_cancel_tournament(
    p_token VARCHAR(255),
    p_tournament_id INT
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

    select count(*) into v_count from adminSchema.tournaments where tournaments.id = p_tournament_id;

    if v_count != 1 then 
        call adminSchema.log(20,'Tournament ID not found');
        return 'Tournament ID not found';
    end if;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(11,'User not authenticated');
        return 'User not authenticated';
    end if;

    if adminSchema.check_permissions(p_user_id,'Employee') = false then    
        call adminSchema.log(11,'Access denied');
        return 'Access denied';
    end if;

    -- Check if tournament is in progress
    if (select count(*) from adminSchema.tournaments where tournaments.id = p_tournament_id and tournaments.status = 1) = 0 then
        call adminSchema.log(20,'Tournament is not in progress');
        return 'Tournament is not in progress';
    end if;

    -- Cancel tournament
    update adminSchema.tournaments set status = 3 where tournaments.id = p_tournament_id;
    call adminSchema.log(21,'Tournament cancelled',p_user_id);
    return 'Tournament cancelled';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.employee_get_users(
    p_token VARCHAR(255),
    p_user_id INT DEFAULT -1
)
RETURNS TABLE (
    id INT,
    username VARCHAR,
    permissions SMALLINT,
    balance NUMERIC
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

    if adminSchema.check_permissions(p_user_id,'Employee') = false then    
        call adminSchema.log(11,'Access denied');
        RAISE EXCEPTION 'Access denied';
    end if;

    if p_user_id = -1 then
        return query select users.id,users.username,users.permissions,users.balance from adminSchema.users;
    else
        return query select users.id,users.username,users.permissions,users.balance from adminSchema.users where users.id = p_user_id;
    end if;
END;
$$;