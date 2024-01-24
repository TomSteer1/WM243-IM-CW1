-- Enables the use of crpt
CREATE EXTENSION pgcrypto;
CREATE EXTENSION "uuid-ossp";

BEGIN;

-- Create initial Schemas
CREATE SCHEMA userSchema;
CREATE SCHEMA adminSchema;

CREATE TABLE adminSchema.Permissions (
    Permission VARCHAR(255) PRIMARY KEY,
    Bit_no SMALLINT NOT NULL
);

-- Create Users table
CREATE TABLE adminSchema.Users (
    ID SERIAL PRIMARY KEY,
    Username VARCHAR(255) UNIQUE NOT NULL,
    Hash VARCHAR(255) NOT NULL,
    Salt VARCHAR(255) NOT NULL,
    Permissions SMALLINT NOT NULL DEFAULT 1,
    Balance NUMERIC(10, 2) DEFAULT 0,
    Token VARCHAR(255)
);

-- Create Statuses table
CREATE TABLE adminSchema.Statuses (
    ID SERIAL PRIMARY KEY,
    Message VARCHAR(255) NOT NULL
);

-- Create Payments table
CREATE TABLE adminSchema.Payments (
    ID uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    UserID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    Status INT DEFAULT 0 REFERENCES adminSchema.Statuses(ID) ON UPDATE CASCADE ON DELETE SET DEFAULT,
    Amount NUMERIC (10,2) DEFAULT 0 NOT NULL,
    External BOOLEAN DEFAULT FALSE NOT NULL,
    Description VARCHAR(255),
    PaymentProcessorID INT
);

-- Create Games table
CREATE TABLE adminSchema.Games (
    ID SERIAL PRIMARY KEY,
    Price NUMERIC(10, 2) DEFAULT 0.00,
    Purchasable BOOLEAN DEFAULT true,
    Name VARCHAR(255) NOT NULL
);

-- Create Items table
CREATE TABLE adminSchema.Items (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Price NUMERIC(10, 2) DEFAULT 0.00,
    Purchasable BOOLEAN DEFAULT true,
    GameID INT REFERENCES adminSchema.Games(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Items Purchases table
CREATE TABLE adminSchema.ItemPurchases (
    ID SERIAL PRIMARY KEY,
    UserID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    ItemID INT REFERENCES adminSchema.Items(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    PaymentID uuid REFERENCES adminSchema.Payments(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create Games Purchases table
CREATE TABLE adminSchema.GamePurchases (
    ID SERIAL PRIMARY KEY,
    UserID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    GameID INT REFERENCES adminSchema.Items(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    PaymentID uuid REFERENCES adminSchema.Payments(ID) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create LogTypes table
CREATE TABLE adminSchema.LogTypes (
    ID SERIAL PRIMARY KEY,
    LogType VARCHAR(255) NOT NULL
);

-- Create Logs table
CREATE TABLE adminSchema.Logs (
    ID SERIAL PRIMARY KEY,
    UserID INT DEFAULT 0 REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE SET NULL,
    LogType INT DEFAULT 0 REFERENCES adminSchema.LogTypes(ID) ON UPDATE CASCADE ON DELETE SET DEFAULT,
    Message TEXT
);

-- Create Teams table
CREATE TABLE adminSchema.Teams (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) UNIQUE NOT NULL,
    LeaderID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE SET NULL
);

-- Create TeamRegistrations table
CREATE TABLE adminSchema.TeamRegistrations (
    ID SERIAL PRIMARY KEY,
    TeamID INT REFERENCES adminSchema.Teams(ID) ON UPDATE CASCADE ON DELETE CASCADE NOT NULL,
    UserID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE CASCADE NOT NULL,
    JoinDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Tournaments table
CREATE TABLE adminSchema.Tournaments (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) UNIQUE NOT NULL,
    StartTimestamp TIMESTAMP,
    EndTimestamp TIMESTAMP,
    GameID INT REFERENCES adminSchema.Games(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    Status INT DEFAULT 5 REFERENCES adminSchema.Statuses(ID) ON UPDATE CASCADE ON DELETE SET DEFAULT
);

-- Create TournamentMatchRegistrations table
CREATE TABLE adminSchema.TournamentRegistrations (
    ID SERIAL PRIMARY KEY,
    TournamentID INT REFERENCES adminSchema.Tournaments(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    TeamID INT REFERENCES adminSchema.Teams(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    JoinDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create TournamentMatches table
CREATE TABLE adminSchema.TournamentMatches (
    ID SERIAL PRIMARY KEY,
    TournamentID INT REFERENCES adminSchema.Tournaments(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    Status INT DEFAULT 0 REFERENCES adminSchema.Statuses(ID) ON UPDATE CASCADE ON DELETE SET DEFAULT
);


-- Create TournamentLeaderboard table
CREATE TABLE adminSchema.TournamentLeaderboard (
    ID SERIAL PRIMARY KEY,
    TournamentID INT REFERENCES adminSchema.Tournaments(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    TeamID INT REFERENCES adminSchema.Teams(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    Score INT
);

-- Create Communities table
CREATE TABLE adminSchema.Communities (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) UNIQUE NOT NULL,
    AdminID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Create CommunityRegistrations table
CREATE TABLE adminSchema.CommunityRegistrations (
    ID SERIAL PRIMARY KEY,
    UserID INT REFERENCES adminSchema.Users(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    CommunityID INT REFERENCES adminSchema.Communities(ID) ON UPDATE CASCADE ON DELETE CASCADE,
    JoinDate TIMESTAMP
);

COMMIT;BEGIN;

-- Insert default values into Statuses table
INSERT INTO adminSchema.Statuses (ID, Message) VALUES (0, 'Unknown');
-- Complete status message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (1,'Complete');
-- Pending status message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (2,'Pending');
-- Cancelled status message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (3,'Cancelled');
-- Error status message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (4,'Error');
-- In Progress status message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (5,'Open');
-- User Registered Message --
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (6,'User registered successfully');
-- Username Already Exists -- 
INSERT INTO adminSchema.Statuses (ID,Message) VALUES (7,'Username already exists');


-- Insert default values into User Types
-- INSERT INTO adminSchema.UserTypes (id,Name) VALUES (0,'User');
-- INSERT INTO adminSchema.UserTypes (id,Name) VALUES (1,'Employee');
-- INSERT INTO adminSchema.UserTypes (id,Name) VALUES (2,'Manager');
-- INSERT INTO adminSchema.UserTypes (id,Name) VALUES (3,'Admin');

-- Create Permission Tables
INSERT INTO adminSchema.Permissions(Permission,Bit_no) VALUES ('User',0);
INSERT INTO adminSchema.Permissions(Permission,Bit_no) VALUES ('Employee',1);
INSERT INTO adminSchema.Permissions(Permission,Bit_no) VALUES ('Manager',2);
INSERT INTO adminSchema.Permissions(Permission,Bit_no) VALUES ('Admin',3);

-- Log Types
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (0,'Unknown');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (1,'Failed Login Attempt');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (2,'Successful Login Attempt');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (3,'Successful Registration');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (4,'Failed Registration');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (5,'Failed Purchase');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (6,'Successful Purchase');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (7,'Failed to adds funds');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (8,'Funds added successfully');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (9,'Transfer Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (10,'Transfer successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (11,'Access denied');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (12,'Payment Modification Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (13,'Payment Modification Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (14,'Team Creation Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (15,'Team Creation Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (16,'Team Join Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (17,'Team Join Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (18,'Team Lookup Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (19,'Team Lookup Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (20,'Tournament Creation Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (21,'Tournament Creation Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (22,'Tournament Cancellation Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (23,'Tournament Cancellation Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (24,'Item Creation Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (25,'Item Creation Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (26,'Game Creation Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (27,'Game Creation Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (28,'Item Deletion Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (29,'Item Deletion Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (30,'Game Deletion Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (31,'Game Deletion Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (32,'User Mimic Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (33,'User Mimic Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (34,'User Ban Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (35,'User Ban Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (36,'Team Leave Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (37,'Team Leave Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (38,'Team Delete Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (39,'Team Delete Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (40,'Tournament Registration Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (41,'Tournament Registration Successful');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (42,'Tournament Lookup Failed');
INSERT INTO adminSchema.LogTypes (id,logtype) VALUES (43,'Tournament Lookup Successful');

-- System User
INSERT into adminSchema.Users (id,username,hash,salt,permissions) VALUES (0,'System','','',0);

-- Test Game
INSERT into adminSchema.Games (id,price,name) VALUES (0,4.99,'Test Game');

-- Test Item
INSERT into adminSchema.Items (id,price,name,GameID) VALUES (0,7.99,'Test Item',0);

COMMIT;CREATE OR REPLACE VIEW adminSchema.list_users
 AS
 SELECT users.id,
    users.username,
    users.permissions,
    users.balance
   FROM adminSchema.users
    WHERE id != 0;


CREATE OR REPLACE VIEW adminSchema.list_teams
 AS
 SELECT teams.id,
    teams.name as team_name,
    users.username as leader_name,
    count(teamregistrations.userid) as member_count
   FROM adminSchema.teams
      JOIN adminSchema.users on teams.leaderid = users.id
      JOIN adminSchema.teamregistrations on teams.id = teamregistrations.teamid
      GROUP BY teams.name, users.username, teams.id;


CREATE OR REPLACE VIEW adminSchema.list_tournaments
 AS
 SELECT tournaments.id,
    tournaments.name as tournament_name,
    games.name as game_name,
    tournaments.starttimestamp,
    tournaments.endtimestamp,
    statuses.message as status_message
   FROM adminSchema.tournaments
      JOIN adminSchema.games on tournaments.gameid = games.id
      JOIN adminSchema.statuses on tournaments.status = statuses.id;


CREATE OR REPLACE VIEW adminSchema.list_item_purchases
  AS 
  SELECT itempurchases.id as purchase_id,
  itempurchases.userid as user_id,
  users.username,
  itempurchases.itemid as item_id,
  statuses.message as status_message,
  items.name as item_name
  FROM adminSchema.itempurchases
    JOIN adminSchema.users on users.id = itempurchases.userid
    JOIN adminSchema.payments on itempurchases.PaymentID = payments.id
    JOIN adminSchema.statuses on statuses.id = payments.status
    JOIN adminSchema.items on items.id = itempurchases.itemid;

CREATE OR REPLACE VIEW adminSchema.list_game_purchases
  AS 
  SELECT gamepurchases.id as purchase_id,
  gamepurchases.userid as user_id,
  users.username,
  gamepurchases.GameID as game_id,
  statuses.message as status_message,
  games.name as game_name
  FROM adminSchema.gamepurchases
    JOIN adminSchema.users on users.id = gamepurchases.userid
    JOIN adminSchema.payments on gamepurchases.PaymentID = payments.id
    JOIN adminSchema.statuses on statuses.id = payments.status
    JOIN adminSchema.games on games.id = gamepurchases.gameid;
    

CREATE OR REPLACE VIEW adminSchema.list_payments
  AS 
  SELECT payments.id as payment_id,
  payments.userid as user_id,
  users.username,
  payments.amount,
  payments.Description,
  statuses.message as status_message
  FROM adminSchema.payments
    JOIN adminSchema.users on users.id = payments.userid
    JOIN adminSchema.statuses on statuses.id = payments.status;



CREATE OR REPLACE VIEW adminSchema.list_items
  AS
  SELECT items.id,
    items.name as item_name,
    items.price,
    games.name as game_name
    FROM adminSchema.items 
    JOIN adminSchema.games on items.GameID = games.id
    WHERE items.Purchasable = true;

CREATE OR REPLACE VIEW adminSchema.list_games
  AS
  SELECT games.id,
    games.name as name,
    games.price
    FROM adminSchema.games
    WHERE games.Purchasable = true;

CREATE OR REPLACE VIEW adminSchema.list_logs
  AS
  SELECT logs.id,
  users.username,
  LogTypes.logtype,
  logs.message
  FROM adminSchema.logs
    JOIN adminSchema.users on logs.userid = users.id
    JOIN adminSchema.LogTypes on logtypes.id = logs.logtype;

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
$$;-- Register
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
GRANT USAGE ON SCHEMA userSchema to db_user;
GRANT USAGE ON SCHEMA employeeSchema to db_employee;CREATE OR REPLACE FUNCTION userSchema.manager_get_logs(
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
$$;CREATE OR REPLACE FUNCTION userSchema.employee_create_tournament(
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

-- Create some example users;

SELECT * from userSchema.register_user('user','user');
SELECT * from userSchema.register_user('employee','employee');
UPDATE adminSchema.users SET permissions = 3 WHERE username = 'employee';
SELECT * from userSchema.register_user('manager','manager');
UPDATE adminSchema.users SET permissions = 7 WHERE username = 'manager';
