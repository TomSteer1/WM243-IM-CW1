-- Register
-- Login
-- Get Balance
-- Make Purchase
-- Get Purchases


CREATE OR REPLACE FUNCTION userSchema.register_user(
    p_username VARCHAR(255),
    p_raw_password VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_count INT;
    salt VARCHAR(255);
    hashed_password VARCHAR(255);
    stored_id INT;
BEGIN
    -- Check if the username already exists
    SELECT COUNT(*) INTO user_count
    FROM adminSchema.users
    WHERE username = p_username;

    -- If the username doesn't exist, generate a random salt, hash the password, and insert the new user
    IF user_count = 0 THEN
        -- Generate a random salt
        salt := gen_salt('bf');

        -- Hash the password with the generated salt
        hashed_password := crypt(p_raw_password, salt);

        -- Insert the new user along with the salt
        INSERT INTO adminSchema.users (username, hash, salt)
        VALUES (p_username, hashed_password, salt);

	SELECT id INTO stored_id
	FROM adminSchema.users
	WHERE username = p_username;
	call adminSchema.log(3,Format('User %s registered',p_username),stored_id);
        RETURN 'User registered successfully';
    ELSE
	call adminSchema.log(4,Format('User %s already exists',p_username));
        RETURN 'Username already exists. Please choose a different one.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.login_user(
    p_username VARCHAR(255),
    p_raw_password VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    stored_hash VARCHAR(255);
    stored_salt VARCHAR(255);
    stored_id INT;
    generated_hash VARCHAR(255);
    user_exists BOOLEAN;
    user_token VARCHAR(32);  -- For simplicity, using md5 for the token
BEGIN
    -- Check if the username exists
    SELECT COUNT(*) INTO user_exists
    FROM adminSchema.users
    WHERE username = p_username;

    -- If the username exists, retrieve the hashed password and salt
    IF user_exists THEN
        if adminSchema.check_permissions((select id from adminSchema.users where username = p_username),'User') = false then
            call adminSchema.log(1,Format('Failed login - User is banned %s',p_username),0);
            RETURN 'User is banned';
        END IF;
        SELECT hash, salt,id INTO stored_hash, stored_salt, stored_id
        FROM adminSchema.users
        WHERE username = p_username;

        -- Hash the provided password using the stored salt
        generated_hash := crypt(p_raw_password, stored_salt);

        -- Compare the generated hash with the stored hashed password
        IF generated_hash = stored_hash THEN
            -- Generate a token (for simplicity, using md5)
            user_token := md5(random()::text || clock_timestamp()::text);
	    UPDATE adminSchema.users set token = user_token where username = p_username;
	    -- Add record to logs --
	        call adminSchema.log(2,Format('User %s logged in',p_username),stored_id);
            -- Return the generated token
            RETURN user_token;
        ELSE
	        call adminSchema.log(1,Format('Failed login attempt for %s',p_username),0);
            RETURN 'Invalid password';
        END IF;
    ELSE
	call adminSchema.log(1,'Failed login attempt');
	RETURN 'User not found';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_balance(
	p_token VARCHAR(255)
)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
	user_balance NUMERIC (10,2);
    user_id INT;
BEGIN
    SELECT adminSchema.auth_user(p_token) into user_id;
	IF adminSchema.check_user_id(user_id) then
		SELECT balance INTO user_balance
		FROM adminSchema.users
		WHERE id = user_id;
		return user_balance;
	ELSE
		RAISE EXCEPTION 'User not found';
	END IF;
		
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.purchase_item(
	p_token VARCHAR(255),
	itemID INT
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
	returnMessage VARCHAR;
    user_balance INT;
    item_count INT;
    item RECORD;
    user_id INT;
    payment_uuid uuid;
BEGIN
    SELECT COUNT(*) INTO item_count 
    FROM adminSchema.list_items
    WHERE id = itemID;

    select adminSchema.auth_user(p_token) into user_id;

    if adminSchema.check_user_id(user_id) = false then
        call adminSchema.log(5,'User not authenticated');
        return 'User not authenticated';
    end if;

    if item_count != 1 then
        call adminSchema.log(5,'Item not found',user_id);
        return 'Item not found';
    end if;

	
    select userSchema.get_balance(p_token) into user_balance;
    select * into item from adminSchema.list_items where id = itemID;
    if user_balance < item.price then
        call adminSchema.log(5,'Insufficient Funds',user_id);
        return 'Insufficient Funds';
    end if;


    SELECT uuid_generate_v4() into payment_uuid;    
    insert into adminSchema.Payments (id,userid,status,amount,description) values (payment_uuid,user_id,2,item.price,Format('Purchased %s',item.item_name));
    insert into adminSchema.ItemPurchases (userid,itemID,PaymentID) values (user_id,itemID,payment_uuid);
    update adminSchema.users set balance = user_balance - item.price where id = user_id;
    return 'Purchase pending approval';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_my_items(
	p_token VARCHAR(255)
)
RETURNS TABLE (
    id int,
    itemid int,
    item_name VARCHAR(255),
    status_message VARCHAR(255)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    returnTable record;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(5,'User not authenticated');
    end if;

    return query select purchase_id,item_id,adminSchema.list_item_purchases.item_name,adminSchema.list_item_purchases.status_message from adminSchema.list_item_purchases where user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.purchase_game(
	p_token VARCHAR(255),
	gameID INT
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
	returnMessage VARCHAR;
    user_balance INT;
    game_count INT;
    game RECORD;
    user_id INT;
    payment_uuid uuid;
BEGIN
    SELECT COUNT(*) INTO game_count
    FROM adminSchema.list_games
    WHERE id = gameID;

    select adminSchema.auth_user(p_token) into user_id;

    if adminSchema.check_user_id(user_id) = false then
        call adminSchema.log(5,'User not authenticated');
        return 'User not authenticated';
    end if;

    if game_count != 1 then
        call adminSchema.log(5,'Game not found',user_id);
        return 'Game not found';
    end if;

	
    select userSchema.get_balance(p_token) into user_balance;
    select * into game from adminSchema.list_games where id = gameID;
    if user_balance < game.price then
        call adminSchema.log(5,'Insufficient Funds',user_id);
        return 'Insufficient Funds';
    end if;

    SELECT uuid_generate_v4() into payment_uuid;    
    insert into adminSchema.Payments (id,userid,status,amount,description) values (payment_uuid,user_id,2,game.price,Format('Purchased %s',game.name));
    insert into adminSchema.GamePurchases (userid,gameID,PaymentID) values (user_id,gameID,payment_uuid);
    update adminSchema.users set balance = user_balance - game.price where id = user_id;
    return 'Purchase pending approval';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_my_games(
	p_token VARCHAR(255)
)
RETURNS TABLE (
    id int,
    gameid int,
    game_name VARCHAR(255),
    status_message VARCHAR(255)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    returnTable record;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(5,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    return query select purchase_id,game_id,adminSchema.list_game_purchases.game_name,adminSchema.list_game_purchases.status_message from adminSchema.list_game_purchases where user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.add_funds(
    p_token VARCHAR(255),
    p_amount NUMERIC(10,2)
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id int;
    balance NUMERIC (10,2);
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(7,'User not authenticated');
        RAISE EXCEPTION 'Not authenticated';
    end if;

    insert into adminSchema.Payments (userid,status,amount,description) values (p_user_id,1,p_amount,'Added funds to account');
    update adminSchema.users set balance = userSchema.get_balance(p_token) + p_amount where id = p_user_id;
    return userSchema.get_balance(p_token);
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_payments(
	p_token VARCHAR(255)
)
RETURNS TABLE (
    id uuid,
    amount NUMERIC,
    description VARCHAR(255)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(5,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    return query select payment_id,adminSchema.list_payments.amount,adminSchema.list_payments.description from adminSchema.list_payments where user_id=p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.transfer_balance(
    p_token VARCHAR(255),
    p_amount NUMERIC,
    p_username VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_req_balance NUMERIC;
    p_dest_user_count INT;
    p_dest_user_id INT;
    p_req_uuid uuid;
    p_dest_uuid uuid;
    p_req_username VARCHAR;
BEGIN

    if p_username = 'System' then
        call adminSchema.log(9,'Can not transfer to system');
        RAISE EXCEPTION 'Can not transfer to system';
    end if;


    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(9,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    select count(*) into p_dest_user_count from adminSchema.list_users where username = p_username;

    if p_dest_user_count != 1 then
        call adminSchema.log(9,Format('User %s not found',p_username),p_user_id);
        RAISE EXCEPTION 'User not found';
    end if;

    if p_amount <= 0 then 
        call adminSchema.log(9,'Invalid amount',p_user_id);
        RAISE EXCEPTION 'Invalid amount';
    end if;

    select id into p_dest_user_id from adminSchema.list_users where username = p_username;
    select balance into p_req_balance from adminSchema.list_users where id = p_user_id;
    select username into p_req_username from adminSchema.list_users where id = p_user_id;

    if p_dest_user_id = p_user_id then
        call adminSchema.log(9,'You cant tranfer to yourself',p_user_id);
        RAISE EXCEPTION 'You cant tranfer to yourself';
    end if;

    if p_amount > p_req_balance then
        call adminSchema.log(9,'Insufficient funds',p_user_id);
        RAISE EXCEPTION 'Insufficient funds';
    end if;


    SELECT uuid_generate_v4() into p_req_uuid;    
    insert into adminSchema.Payments (id,userid,status,amount,description) values (p_req_uuid,p_user_id,2,p_amount,Format('Transfer to %s',p_username));
    update adminSchema.users set balance = balance - p_amount where id = p_user_id;

    SELECT uuid_generate_v4() into p_dest_uuid;    
    insert into adminSchema.Payments (id,userid,status,amount,description) values (p_dest_uuid,p_dest_user_id,2,p_amount,Format('Tranfer from %s',p_req_username));
    update adminSchema.users set balance = balance + p_amount where id = p_dest_user_id;    

    call adminSchema.log(10,Format('Tranfered £%s from %s to %s',p_amount,p_req_username,p_username),p_user_id);
    return 'Tranfer complete';

END;
$$;

CREATE OR REPLACE FUNCTION userSchema.create_team(
    p_token VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(14,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if p_team_name = '' then
        call adminSchema.log(14,'Team name can not be empty',p_user_id);
        RAISE EXCEPTION 'Team name can not be empty';
    end if;

    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) > 0 then
        call adminSchema.log(14,Format('Team %s already exists',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team already exists';
    end if;

    insert into adminSchema.teams (name,leaderid) values (p_team_name,p_user_id);
    insert into adminSchema.teamregistrations (userid,teamid) values (p_user_id,(select id from adminSchema.teams where name = p_team_name));
    return 'Team created';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_teams(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    team_name VARCHAR(255),
    leader_name VARCHAR(255),
    member_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(18,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    call adminSchema.log(19,Format('User %s looked up teams',p_user_id),p_user_id);
    return query select list_teams.team_name,list_teams.leader_name,list_teams.member_count from adminSchema.list_teams;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.join_team(
    p_token VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(16,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if p_team_name = '' then
        call adminSchema.log(16,'Team name can not be empty',p_user_id);
        RAISE EXCEPTION 'Team name can not be empty';
    end if;

    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) = 0 then
        call adminSchema.log(16,Format('Team %s does not exist',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team does not exist';
    end if;

    select id into p_team_id from adminSchema.teams where name = p_team_name;

    if (select count(*) from adminSchema.teamregistrations where userid = p_user_id and teamid = p_team_id) > 0 then
        call adminSchema.log(16,Format('User %s is already a member of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'User is already a member of this team';
    end if;

    insert into adminSchema.teamregistrations (userid,teamid) values (p_user_id,p_team_id);
    call adminSchema.log(17,Format('User %s joined team %s',p_user_id,p_team_name),p_user_id);
    return 'Joined team';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_team(
    p_token VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS TABLE (
    username VARCHAR(255),
    joined_date TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(18,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    if p_team_name = '' then
        call adminSchema.log(18,'Team name can not be empty',p_user_id);
        RAISE EXCEPTION 'Team name can not be empty';
    end if;

    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) = 0 then
        call adminSchema.log(18,Format('Team %s does not exist',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team does not exist';
    end if;

    select id into p_team_id from adminSchema.teams where name = p_team_name;
    call adminSchema.log(19,Format('User %s looked up team %s',p_user_id,p_team_name),p_user_id);
    return query select users.username,teamregistrations.JoinDate from adminSchema.teamregistrations join adminSchema.users on users.id = teamregistrations.userid where teamid = p_team_id;
END;
$$;


CREATE OR REPLACE FUNCTION userSchema.get_tournaments(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    id INT,
    tournament_name VARCHAR(255),
    game_name VARCHAR(255),
    starttimestamp TIMESTAMP,
    endtimestamp TIMESTAMP,
    status_message VARCHAR(255)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(21,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    call adminSchema.log(23,Format('User %s looked up tournaments',p_user_id),p_user_id);
    return query select list_tournaments.id,list_tournaments.tournament_name,list_tournaments.game_name,list_tournaments.starttimestamp,list_tournaments.endtimestamp,list_tournaments.status_message from adminSchema.list_tournaments;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_games(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    id INT,
    name VARCHAR(255),
    price NUMERIC(10,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;

    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(21,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;

    call adminSchema.log(22,Format('User %s looked up games',p_user_id),p_user_id);
    return query select list_games.id,list_games.name,list_games.price from adminSchema.list_games;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_items(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    id INT,
    name VARCHAR(255),
    price NUMERIC(10,2),
    game_name VARCHAR(255)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(21,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    call adminSchema.log(22,Format('User %s looked up items',p_user_id),p_user_id);
    return query select * from adminSchema.list_items;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_my_teams(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    team_name VARCHAR(255),
    joined_date TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(21,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    call adminSchema.log(22,Format('User %s looked up their teams',p_user_id),p_user_id);
    return query select teams.name,teamregistrations.joindate from adminSchema.teamregistrations join adminSchema.teams on teams.id = teamregistrations.teamid where userid = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.leave_team(
    p_token VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(36,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    if p_team_name = '' then
        call adminSchema.log(36,'Team name can not be empty');
        RAISE EXCEPTION 'Team name can not be empty';
    end if;
    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) = 0 then
        call adminSchema.log(36,Format('Team %s does not exist',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team does not exist';
    end if;
    select id into p_team_id from adminSchema.teams where name = p_team_name;
    if (select count(*) from adminSchema.teamregistrations where userid = p_user_id and teamid = p_team_id) = 0 then
        call adminSchema.log(36,Format('User %s is not a member of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'User is not a member of this team';
    end if;

    -- Check if the user is the leader
    if (select count(*) from adminSchema.teams where leaderid = p_user_id and id = p_team_id) = 1 then
        call adminSchema.log(36,Format('User %s is the leader of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'You are the leader of this team. Please delete the team instead';
    end if;

    delete from adminSchema.teamregistrations where userid = p_user_id and teamid = p_team_id;
    call adminSchema.log(37,Format('User %s left team %s',p_user_id,p_team_name),p_user_id);
    return 'Left team';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.delete_team(
    p_token VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(38,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    if p_team_name = '' then
        call adminSchema.log(38,'Team name can not be empty');
        RAISE EXCEPTION 'Team name can not be empty';
    end if;
    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) = 0 then
        call adminSchema.log(38,Format('Team %s does not exist',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team does not exist';
    end if;
    select id into p_team_id from adminSchema.teams where name = p_team_name;
    if (select count(*) from adminSchema.teamregistrations where userid = p_user_id and teamid = p_team_id) = 0 then
        call adminSchema.log(38,Format('User %s is not a member of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'User is not a member of this team';
    end if;

    -- Check if the user is the leader
    if (select count(*) from adminSchema.teams where leaderid = p_user_id and id = p_team_id) = 0 then
        call adminSchema.log(38,Format('User %s is not the leader of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'You are not the leader of this team';
    end if;

    delete from adminSchema.teamregistrations where teamid = p_team_id;
    delete from adminSchema.teams where id = p_team_id;
    call adminSchema.log(39,Format('User %s deleted team %s',p_user_id,p_team_name),p_user_id);
    return 'Deleted team';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.join_tournament(
    p_token VARCHAR(255),
    p_tournament_name VARCHAR(255),
    p_team_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
    p_tournament_id INT;
    p_team_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(40,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    if p_tournament_name = '' then
        call adminSchema.log(40,'Tournament name can not be empty');
        RAISE EXCEPTION 'Tournament name can not be empty';
    end if;
    if p_team_name = '' then
        call adminSchema.log(40,'Team name can not be empty');
        RAISE EXCEPTION 'Team name can not be empty';
    end if;
    if (select count(*) from adminSchema.list_tournaments where tournament_name = p_tournament_name) = 0 then
        call adminSchema.log(40,Format('Tournament %s does not exist',p_tournament_name),p_user_id);
        RAISE EXCEPTION 'Tournament does not exist';
    end if;
    if (select count(*) from adminSchema.list_teams where team_name = p_team_name) = 0 then
        call adminSchema.log(40,Format('Team %s does not exist',p_team_name),p_user_id);
        RAISE EXCEPTION 'Team does not exist';
    end if;
    select id into p_tournament_id from adminSchema.tournaments where name = p_tournament_name;
    select id into p_team_id from adminSchema.teams where name = p_team_name;
    if (select count(*) from adminSchema.teams where leaderid = p_user_id and id = p_team_id) = 0 then
        call adminSchema.log(40,Format('User %s is not the leader of %s',p_user_id,p_team_name),p_user_id);
        RAISE EXCEPTION 'You are not the leader of this team';
    end if;
    if (select count(*) from adminSchema.tournamentregistrations where teamid = p_team_id and tournamentid = p_tournament_id) > 0 then
        call adminSchema.log(40,Format('Team %s is already registered for %s',p_team_name,p_tournament_name),p_user_id);
        RAISE EXCEPTION 'User is already registered for this tournament';
    end if;
    insert into adminSchema.tournamentregistrations (teamid,tournamentid) values (p_team_id,p_tournament_id);
    call adminSchema.log(41,Format('User %s registered team %s for tournament %s',p_user_id,p_team_name,p_tournament_name),p_user_id);
    return 'Registered team';
END;
$$;

CREATE OR REPLACE FUNCTION userSchema.get_my_tournaments(
    p_token VARCHAR(255)
)
RETURNS TABLE (
    tournament_name VARCHAR(255),
    team_name VARCHAR(255),
    joined_date TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id INT;
BEGIN
    select adminSchema.auth_user(p_token) into p_user_id;
    if adminSchema.check_user_id(p_user_id) = false then
        call adminSchema.log(42,'User not authenticated');
        RAISE EXCEPTION 'User not authenticated';
    end if;
    call adminSchema.log(43,Format('User %s looked up their tournaments',p_user_id),p_user_id);
    return query select 
        tournaments.name,
        teams.name,
        tournamentregistrations.joindate
        from adminSchema.tournamentregistrations
            join adminSchema.teams on teams.id = tournamentregistrations.teamid
            join adminSchema.tournaments on tournaments.id = tournamentregistrations.tournamentid
            join adminSchema.teamregistrations on teamregistrations.teamid = teams.id
            where teamregistrations.userid = p_user_id;
END;
$$;
