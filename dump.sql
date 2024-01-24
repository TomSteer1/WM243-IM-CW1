--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Ubuntu 16.1-1.pgdg22.04+1)
-- Dumped by pg_dump version 16.1 (Ubuntu 16.1-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE gaming;
--
-- Name: gaming; Type: DATABASE; Schema: -; Owner: db_admin
--
--
-- Drop roles
--

DROP ROLE db_admin;
DROP ROLE db_user;

--
-- Roles
--

CREATE ROLE db_admin;
ALTER ROLE db_admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:EcT3R/56gNx+2g+pJ/wqsQ==$ATxjQTaQwWA4wo49ziUfxZwce6Q1SBX1VeuW0tKwJwE=:31quRg+D1jw22OdjYCHl3cQcOHUraCpPuv8+O87aom8=';
CREATE ROLE db_user;
ALTER ROLE db_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:MrmXdnGkvOAfgKMfmCJ0Ew==$c3KE1IDgoVD9wrXKXztih9+K/B4k8ULvTjbubKx/QlE=:HERUhaDgeQf8teFBzcsNj0i6Xrix9IJTTJ46cbUr6jg=';


CREATE DATABASE gaming;


ALTER DATABASE gaming OWNER TO db_admin;

\connect gaming

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: adminschema; Type: SCHEMA; Schema: -; Owner: db_admin
--

CREATE SCHEMA adminschema;


ALTER SCHEMA adminschema OWNER TO db_admin;

--
-- Name: userschema; Type: SCHEMA; Schema: -; Owner: db_admin
--

CREATE SCHEMA userschema;


ALTER SCHEMA userschema OWNER TO db_admin;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: auth_user(character varying); Type: FUNCTION; Schema: adminschema; Owner: db_admin
--

CREATE FUNCTION adminschema.auth_user(p_token character varying) RETURNS integer
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


ALTER FUNCTION adminschema.auth_user(p_token character varying) OWNER TO db_admin;

--
-- Name: check_permissions(integer, character varying); Type: FUNCTION; Schema: adminschema; Owner: db_admin
--

CREATE FUNCTION adminschema.check_permissions(p_user_id integer, p_permission character varying) RETURNS boolean
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


ALTER FUNCTION adminschema.check_permissions(p_user_id integer, p_permission character varying) OWNER TO db_admin;

--
-- Name: check_user_id(integer); Type: FUNCTION; Schema: adminschema; Owner: db_admin
--

CREATE FUNCTION adminschema.check_user_id(user_id integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION adminschema.check_user_id(user_id integer) OWNER TO db_admin;

--
-- Name: log(integer, character varying); Type: PROCEDURE; Schema: adminschema; Owner: db_admin
--

CREATE PROCEDURE adminschema.log(IN logtype integer, IN message character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO adminSchema.logs (logtype,userid,message) values (logtype,0,message);
END;
$$;


ALTER PROCEDURE adminschema.log(IN logtype integer, IN message character varying) OWNER TO db_admin;

--
-- Name: log(integer, character varying, integer); Type: PROCEDURE; Schema: adminschema; Owner: db_admin
--

CREATE PROCEDURE adminschema.log(IN logtype integer, IN message character varying, IN userid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO adminSchema.logs (logtype,userid,message) values (logtype,userid,message);
END;
$$;


ALTER PROCEDURE adminschema.log(IN logtype integer, IN message character varying, IN userid integer) OWNER TO db_admin;

--
-- Name: add_funds(character varying, numeric); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.add_funds(p_token character varying, p_amount numeric) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.add_funds(p_token character varying, p_amount numeric) OWNER TO db_admin;

--
-- Name: create_team(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.create_team(p_token character varying, p_team_name character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.create_team(p_token character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: delete_team(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.delete_team(p_token character varying, p_team_name character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.delete_team(p_token character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: employee_cancel_tournament(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.employee_cancel_tournament(p_token character varying, p_tournament_id integer) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.employee_cancel_tournament(p_token character varying, p_tournament_id integer) OWNER TO db_admin;

--
-- Name: employee_create_tournament(character varying, character varying, integer, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.employee_create_tournament(p_token character varying, p_name character varying, p_game_id integer, p_start_date timestamp without time zone, p_end_date timestamp without time zone) RETURNS TABLE(id integer, name character varying, game_id integer, start_date timestamp without time zone, end_date timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.employee_create_tournament(p_token character varying, p_name character varying, p_game_id integer, p_start_date timestamp without time zone, p_end_date timestamp without time zone) OWNER TO db_admin;

--
-- Name: employee_get_users(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.employee_get_users(p_token character varying, p_user_id integer DEFAULT '-1'::integer) RETURNS TABLE(id integer, username character varying, permissions smallint, balance numeric)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.employee_get_users(p_token character varying, p_user_id integer) OWNER TO db_admin;

--
-- Name: get_balance(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_balance(p_token character varying) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_balance(p_token character varying) OWNER TO db_admin;

--
-- Name: get_games(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_games(p_token character varying) RETURNS TABLE(id integer, name character varying, price numeric)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_games(p_token character varying) OWNER TO db_admin;

--
-- Name: get_items(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_items(p_token character varying) RETURNS TABLE(id integer, name character varying, price numeric, game_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_items(p_token character varying) OWNER TO db_admin;

--
-- Name: get_my_games(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_my_games(p_token character varying) RETURNS TABLE(id integer, gameid integer, game_name character varying, status_message character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_my_games(p_token character varying) OWNER TO db_admin;

--
-- Name: get_my_items(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_my_items(p_token character varying) RETURNS TABLE(id integer, itemid integer, item_name character varying, status_message character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_my_items(p_token character varying) OWNER TO db_admin;

--
-- Name: get_my_teams(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_my_teams(p_token character varying) RETURNS TABLE(team_name character varying, joined_date timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_my_teams(p_token character varying) OWNER TO db_admin;

--
-- Name: get_my_tournaments(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_my_tournaments(p_token character varying) RETURNS TABLE(tournament_name character varying, team_name character varying, joined_date timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_my_tournaments(p_token character varying) OWNER TO db_admin;

--
-- Name: get_payments(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_payments(p_token character varying) RETURNS TABLE(id uuid, amount numeric, description character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_payments(p_token character varying) OWNER TO db_admin;

--
-- Name: get_team(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_team(p_token character varying, p_team_name character varying) RETURNS TABLE(username character varying, joined_date timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_team(p_token character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: get_teams(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_teams(p_token character varying) RETURNS TABLE(team_name character varying, leader_name character varying, member_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_teams(p_token character varying) OWNER TO db_admin;

--
-- Name: get_tournaments(character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.get_tournaments(p_token character varying) RETURNS TABLE(id integer, tournament_name character varying, game_name character varying, starttimestamp timestamp without time zone, endtimestamp timestamp without time zone, status_message character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.get_tournaments(p_token character varying) OWNER TO db_admin;

--
-- Name: join_team(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.join_team(p_token character varying, p_team_name character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.join_team(p_token character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: join_tournament(character varying, character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.join_tournament(p_token character varying, p_tournament_name character varying, p_team_name character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.join_tournament(p_token character varying, p_tournament_name character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: leave_team(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.leave_team(p_token character varying, p_team_name character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.leave_team(p_token character varying, p_team_name character varying) OWNER TO db_admin;

--
-- Name: login_user(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.login_user(p_username character varying, p_raw_password character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.login_user(p_username character varying, p_raw_password character varying) OWNER TO db_admin;

--
-- Name: manager_approve_payment(character varying, uuid); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_approve_payment(p_token character varying, p_payment_id uuid) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_approve_payment(p_token character varying, p_payment_id uuid) OWNER TO db_admin;

--
-- Name: manager_ban_user(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_ban_user(p_token character varying, p_username character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_ban_user(p_token character varying, p_username character varying) OWNER TO db_admin;

--
-- Name: manager_cancel_payment(character varying, uuid); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_cancel_payment(p_token character varying, p_payment_id uuid) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_cancel_payment(p_token character varying, p_payment_id uuid) OWNER TO db_admin;

--
-- Name: manager_create_game(character varying, character varying, numeric); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_create_game(p_token character varying, p_name character varying, p_price numeric) RETURNS TABLE(id integer, name character varying, price numeric)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_create_game(p_token character varying, p_name character varying, p_price numeric) OWNER TO db_admin;

--
-- Name: manager_create_item(character varying, character varying, numeric, integer, boolean); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_create_item(p_token character varying, p_name character varying, p_price numeric, p_game_id integer, p_purchasable boolean DEFAULT true) RETURNS TABLE(id integer, name character varying, price numeric, game_id integer, purchasable boolean)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_create_item(p_token character varying, p_name character varying, p_price numeric, p_game_id integer, p_purchasable boolean) OWNER TO db_admin;

--
-- Name: manager_delete_game(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_delete_game(p_token character varying, p_game_id integer) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_delete_game(p_token character varying, p_game_id integer) OWNER TO db_admin;

--
-- Name: manager_delete_item(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_delete_item(p_token character varying, p_item_id integer) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_delete_item(p_token character varying, p_item_id integer) OWNER TO db_admin;

--
-- Name: manager_get_logs(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_get_logs(p_token character varying, p_logtype integer DEFAULT '-1'::integer) RETURNS TABLE(id integer, username character varying, logtype character varying, message text)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_get_logs(p_token character varying, p_logtype integer) OWNER TO db_admin;

--
-- Name: manager_get_payments(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_get_payments(p_token character varying, p_req_user_id integer DEFAULT '-1'::integer) RETURNS TABLE(id uuid, username character varying, payment_amount numeric, description character varying, status character varying)
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_get_payments(p_token character varying, p_req_user_id integer) OWNER TO db_admin;

--
-- Name: manager_mimic_user(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_mimic_user(p_token character varying, p_username character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_mimic_user(p_token character varying, p_username character varying) OWNER TO db_admin;

--
-- Name: manager_unban_user(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.manager_unban_user(p_token character varying, p_username character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.manager_unban_user(p_token character varying, p_username character varying) OWNER TO db_admin;

--
-- Name: purchase_game(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.purchase_game(p_token character varying, gameid integer) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.purchase_game(p_token character varying, gameid integer) OWNER TO db_admin;

--
-- Name: purchase_item(character varying, integer); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.purchase_item(p_token character varying, itemid integer) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.purchase_item(p_token character varying, itemid integer) OWNER TO db_admin;

--
-- Name: register_user(character varying, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.register_user(p_username character varying, p_raw_password character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.register_user(p_username character varying, p_raw_password character varying) OWNER TO db_admin;

--
-- Name: transfer_balance(character varying, numeric, character varying); Type: FUNCTION; Schema: userschema; Owner: db_admin
--

CREATE FUNCTION userschema.transfer_balance(p_token character varying, p_amount numeric, p_username character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
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


ALTER FUNCTION userschema.transfer_balance(p_token character varying, p_amount numeric, p_username character varying) OWNER TO db_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: communities; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.communities (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    adminid integer
);


ALTER TABLE adminschema.communities OWNER TO db_admin;

--
-- Name: communities_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.communities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.communities_id_seq OWNER TO db_admin;

--
-- Name: communities_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.communities_id_seq OWNED BY adminschema.communities.id;


--
-- Name: communityregistrations; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.communityregistrations (
    id integer NOT NULL,
    userid integer,
    communityid integer,
    joindate timestamp without time zone
);


ALTER TABLE adminschema.communityregistrations OWNER TO db_admin;

--
-- Name: communityregistrations_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.communityregistrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.communityregistrations_id_seq OWNER TO db_admin;

--
-- Name: communityregistrations_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.communityregistrations_id_seq OWNED BY adminschema.communityregistrations.id;


--
-- Name: gamepurchases; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.gamepurchases (
    id integer NOT NULL,
    userid integer,
    gameid integer,
    paymentid uuid
);


ALTER TABLE adminschema.gamepurchases OWNER TO db_admin;

--
-- Name: gamepurchases_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.gamepurchases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.gamepurchases_id_seq OWNER TO db_admin;

--
-- Name: gamepurchases_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.gamepurchases_id_seq OWNED BY adminschema.gamepurchases.id;


--
-- Name: games; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.games (
    id integer NOT NULL,
    price numeric(10,2) DEFAULT 0.00,
    purchasable boolean DEFAULT true,
    name character varying(255) NOT NULL
);


ALTER TABLE adminschema.games OWNER TO db_admin;

--
-- Name: games_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.games_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.games_id_seq OWNER TO db_admin;

--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.games_id_seq OWNED BY adminschema.games.id;


--
-- Name: itempurchases; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.itempurchases (
    id integer NOT NULL,
    userid integer,
    itemid integer,
    paymentid uuid
);


ALTER TABLE adminschema.itempurchases OWNER TO db_admin;

--
-- Name: itempurchases_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.itempurchases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.itempurchases_id_seq OWNER TO db_admin;

--
-- Name: itempurchases_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.itempurchases_id_seq OWNED BY adminschema.itempurchases.id;


--
-- Name: items; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.items (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    price numeric(10,2) DEFAULT 0.00,
    purchasable boolean DEFAULT true,
    gameid integer
);


ALTER TABLE adminschema.items OWNER TO db_admin;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.items_id_seq OWNER TO db_admin;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.items_id_seq OWNED BY adminschema.items.id;


--
-- Name: payments; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    userid integer,
    status integer DEFAULT 0,
    amount numeric(10,2) DEFAULT 0 NOT NULL,
    external boolean DEFAULT false NOT NULL,
    description character varying(255),
    paymentprocessorid integer
);


ALTER TABLE adminschema.payments OWNER TO db_admin;

--
-- Name: statuses; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.statuses (
    id integer NOT NULL,
    message character varying(255) NOT NULL
);


ALTER TABLE adminschema.statuses OWNER TO db_admin;

--
-- Name: users; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    hash character varying(255) NOT NULL,
    salt character varying(255) NOT NULL,
    permissions smallint DEFAULT 1 NOT NULL,
    balance numeric(10,2) DEFAULT 0,
    token character varying(255)
);


ALTER TABLE adminschema.users OWNER TO db_admin;

--
-- Name: list_game_purchases; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_game_purchases AS
 SELECT gamepurchases.id AS purchase_id,
    gamepurchases.userid AS user_id,
    users.username,
    gamepurchases.gameid AS game_id,
    statuses.message AS status_message,
    games.name AS game_name
   FROM ((((adminschema.gamepurchases
     JOIN adminschema.users ON ((users.id = gamepurchases.userid)))
     JOIN adminschema.payments ON ((gamepurchases.paymentid = payments.id)))
     JOIN adminschema.statuses ON ((statuses.id = payments.status)))
     JOIN adminschema.games ON ((games.id = gamepurchases.gameid)));


ALTER VIEW adminschema.list_game_purchases OWNER TO db_admin;

--
-- Name: list_games; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_games AS
 SELECT id,
    name,
    price
   FROM adminschema.games
  WHERE (purchasable = true);


ALTER VIEW adminschema.list_games OWNER TO db_admin;

--
-- Name: list_item_purchases; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_item_purchases AS
 SELECT itempurchases.id AS purchase_id,
    itempurchases.userid AS user_id,
    users.username,
    itempurchases.itemid AS item_id,
    statuses.message AS status_message,
    items.name AS item_name
   FROM ((((adminschema.itempurchases
     JOIN adminschema.users ON ((users.id = itempurchases.userid)))
     JOIN adminschema.payments ON ((itempurchases.paymentid = payments.id)))
     JOIN adminschema.statuses ON ((statuses.id = payments.status)))
     JOIN adminschema.items ON ((items.id = itempurchases.itemid)));


ALTER VIEW adminschema.list_item_purchases OWNER TO db_admin;

--
-- Name: list_items; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_items AS
 SELECT items.id,
    items.name AS item_name,
    items.price,
    games.name AS game_name
   FROM (adminschema.items
     JOIN adminschema.games ON ((items.gameid = games.id)))
  WHERE (items.purchasable = true);


ALTER VIEW adminschema.list_items OWNER TO db_admin;

--
-- Name: logs; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.logs (
    id integer NOT NULL,
    userid integer DEFAULT 0,
    logtype integer DEFAULT 0,
    message text
);


ALTER TABLE adminschema.logs OWNER TO db_admin;

--
-- Name: logtypes; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.logtypes (
    id integer NOT NULL,
    logtype character varying(255) NOT NULL
);


ALTER TABLE adminschema.logtypes OWNER TO db_admin;

--
-- Name: list_logs; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_logs AS
 SELECT logs.id,
    users.username,
    logtypes.logtype,
    logs.message
   FROM ((adminschema.logs
     JOIN adminschema.users ON ((logs.userid = users.id)))
     JOIN adminschema.logtypes ON ((logtypes.id = logs.logtype)));


ALTER VIEW adminschema.list_logs OWNER TO db_admin;

--
-- Name: list_payments; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_payments AS
 SELECT payments.id AS payment_id,
    payments.userid AS user_id,
    users.username,
    payments.amount,
    payments.description,
    statuses.message AS status_message
   FROM ((adminschema.payments
     JOIN adminschema.users ON ((users.id = payments.userid)))
     JOIN adminschema.statuses ON ((statuses.id = payments.status)));


ALTER VIEW adminschema.list_payments OWNER TO db_admin;

--
-- Name: teamregistrations; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.teamregistrations (
    id integer NOT NULL,
    teamid integer NOT NULL,
    userid integer NOT NULL,
    joindate timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE adminschema.teamregistrations OWNER TO db_admin;

--
-- Name: teams; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.teams (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    leaderid integer
);


ALTER TABLE adminschema.teams OWNER TO db_admin;

--
-- Name: list_teams; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_teams AS
 SELECT teams.id,
    teams.name AS team_name,
    users.username AS leader_name,
    count(teamregistrations.userid) AS member_count
   FROM ((adminschema.teams
     JOIN adminschema.users ON ((teams.leaderid = users.id)))
     JOIN adminschema.teamregistrations ON ((teams.id = teamregistrations.teamid)))
  GROUP BY teams.name, users.username, teams.id;


ALTER VIEW adminschema.list_teams OWNER TO db_admin;

--
-- Name: tournaments; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.tournaments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    starttimestamp timestamp without time zone,
    endtimestamp timestamp without time zone,
    gameid integer,
    status integer DEFAULT 5
);


ALTER TABLE adminschema.tournaments OWNER TO db_admin;

--
-- Name: list_tournaments; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_tournaments AS
 SELECT tournaments.id,
    tournaments.name AS tournament_name,
    games.name AS game_name,
    tournaments.starttimestamp,
    tournaments.endtimestamp,
    statuses.message AS status_message
   FROM ((adminschema.tournaments
     JOIN adminschema.games ON ((tournaments.gameid = games.id)))
     JOIN adminschema.statuses ON ((tournaments.status = statuses.id)));


ALTER VIEW adminschema.list_tournaments OWNER TO db_admin;

--
-- Name: list_users; Type: VIEW; Schema: adminschema; Owner: db_admin
--

CREATE VIEW adminschema.list_users AS
 SELECT id,
    username,
    permissions,
    balance
   FROM adminschema.users
  WHERE (id <> 0);


ALTER VIEW adminschema.list_users OWNER TO db_admin;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.logs_id_seq OWNER TO db_admin;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.logs_id_seq OWNED BY adminschema.logs.id;


--
-- Name: logtypes_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.logtypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.logtypes_id_seq OWNER TO db_admin;

--
-- Name: logtypes_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.logtypes_id_seq OWNED BY adminschema.logtypes.id;


--
-- Name: permissions; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.permissions (
    permission character varying(255) NOT NULL,
    bit_no smallint NOT NULL
);


ALTER TABLE adminschema.permissions OWNER TO db_admin;

--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.statuses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.statuses_id_seq OWNER TO db_admin;

--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.statuses_id_seq OWNED BY adminschema.statuses.id;


--
-- Name: teamregistrations_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.teamregistrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.teamregistrations_id_seq OWNER TO db_admin;

--
-- Name: teamregistrations_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.teamregistrations_id_seq OWNED BY adminschema.teamregistrations.id;


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.teams_id_seq OWNER TO db_admin;

--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.teams_id_seq OWNED BY adminschema.teams.id;


--
-- Name: tournamentleaderboard; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.tournamentleaderboard (
    id integer NOT NULL,
    tournamentid integer,
    teamid integer,
    score integer
);


ALTER TABLE adminschema.tournamentleaderboard OWNER TO db_admin;

--
-- Name: tournamentleaderboard_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.tournamentleaderboard_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.tournamentleaderboard_id_seq OWNER TO db_admin;

--
-- Name: tournamentleaderboard_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.tournamentleaderboard_id_seq OWNED BY adminschema.tournamentleaderboard.id;


--
-- Name: tournamentmatches; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.tournamentmatches (
    id integer NOT NULL,
    tournamentid integer,
    status integer DEFAULT 0
);


ALTER TABLE adminschema.tournamentmatches OWNER TO db_admin;

--
-- Name: tournamentmatches_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.tournamentmatches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.tournamentmatches_id_seq OWNER TO db_admin;

--
-- Name: tournamentmatches_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.tournamentmatches_id_seq OWNED BY adminschema.tournamentmatches.id;


--
-- Name: tournamentregistrations; Type: TABLE; Schema: adminschema; Owner: db_admin
--

CREATE TABLE adminschema.tournamentregistrations (
    id integer NOT NULL,
    tournamentid integer,
    teamid integer,
    joindate timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE adminschema.tournamentregistrations OWNER TO db_admin;

--
-- Name: tournamentregistrations_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.tournamentregistrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.tournamentregistrations_id_seq OWNER TO db_admin;

--
-- Name: tournamentregistrations_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.tournamentregistrations_id_seq OWNED BY adminschema.tournamentregistrations.id;


--
-- Name: tournaments_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.tournaments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.tournaments_id_seq OWNER TO db_admin;

--
-- Name: tournaments_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.tournaments_id_seq OWNED BY adminschema.tournaments.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: adminschema; Owner: db_admin
--

CREATE SEQUENCE adminschema.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adminschema.users_id_seq OWNER TO db_admin;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: adminschema; Owner: db_admin
--

ALTER SEQUENCE adminschema.users_id_seq OWNED BY adminschema.users.id;


--
-- Name: communities id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communities ALTER COLUMN id SET DEFAULT nextval('adminschema.communities_id_seq'::regclass);


--
-- Name: communityregistrations id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communityregistrations ALTER COLUMN id SET DEFAULT nextval('adminschema.communityregistrations_id_seq'::regclass);


--
-- Name: gamepurchases id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.gamepurchases ALTER COLUMN id SET DEFAULT nextval('adminschema.gamepurchases_id_seq'::regclass);


--
-- Name: games id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.games ALTER COLUMN id SET DEFAULT nextval('adminschema.games_id_seq'::regclass);


--
-- Name: itempurchases id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.itempurchases ALTER COLUMN id SET DEFAULT nextval('adminschema.itempurchases_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.items ALTER COLUMN id SET DEFAULT nextval('adminschema.items_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logs ALTER COLUMN id SET DEFAULT nextval('adminschema.logs_id_seq'::regclass);


--
-- Name: logtypes id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logtypes ALTER COLUMN id SET DEFAULT nextval('adminschema.logtypes_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.statuses ALTER COLUMN id SET DEFAULT nextval('adminschema.statuses_id_seq'::regclass);


--
-- Name: teamregistrations id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teamregistrations ALTER COLUMN id SET DEFAULT nextval('adminschema.teamregistrations_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teams ALTER COLUMN id SET DEFAULT nextval('adminschema.teams_id_seq'::regclass);


--
-- Name: tournamentleaderboard id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentleaderboard ALTER COLUMN id SET DEFAULT nextval('adminschema.tournamentleaderboard_id_seq'::regclass);


--
-- Name: tournamentmatches id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentmatches ALTER COLUMN id SET DEFAULT nextval('adminschema.tournamentmatches_id_seq'::regclass);


--
-- Name: tournamentregistrations id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentregistrations ALTER COLUMN id SET DEFAULT nextval('adminschema.tournamentregistrations_id_seq'::regclass);


--
-- Name: tournaments id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournaments ALTER COLUMN id SET DEFAULT nextval('adminschema.tournaments_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.users ALTER COLUMN id SET DEFAULT nextval('adminschema.users_id_seq'::regclass);


--
-- Data for Name: communities; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.communities (id, name, adminid) FROM stdin;
\.


--
-- Data for Name: communityregistrations; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.communityregistrations (id, userid, communityid, joindate) FROM stdin;
\.


--
-- Data for Name: gamepurchases; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.gamepurchases (id, userid, gameid, paymentid) FROM stdin;
1	1	0	f9dd6b6f-f0a3-477d-b8ab-24465354497f
\.


--
-- Data for Name: games; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.games (id, price, purchasable, name) FROM stdin;
0	4.99	t	Test Game
\.


--
-- Data for Name: itempurchases; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.itempurchases (id, userid, itemid, paymentid) FROM stdin;
1	1	0	588e2657-035c-403d-b341-fbbd81f6f00f
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.items (id, name, price, purchasable, gameid) FROM stdin;
0	Test Item	7.99	t	0
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.logs (id, userid, logtype, message) FROM stdin;
1	1	3	User user registered
2	2	3	User employee registered
3	3	3	User manager registered
4	1	2	User user logged in
5	0	4	User user already exists
6	1	2	User user logged in
7	1	2	User user logged in
8	1	22	User 1 looked up items
9	1	2	User user logged in
10	1	22	User 1 looked up games
11	1	2	User user logged in
12	1	2	User user logged in
13	1	2	User user logged in
14	1	2	User user logged in
15	1	2	User user logged in
16	1	2	User user logged in
17	1	2	User user logged in
18	1	2	User user logged in
19	1	2	User user logged in
20	4	3	User user2 registered
21	1	2	User user logged in
22	1	10	Tranfered £100 from user to user2
23	1	2	User user logged in
24	4	2	User user2 logged in
25	1	2	User user logged in
26	1	19	User 1 looked up teams
27	1	2	User user logged in
28	1	2	User user logged in
29	1	19	User 1 looked up teams
30	4	2	User user2 logged in
31	4	17	User 4 joined team test_team
32	1	2	User user logged in
33	1	22	User 1 looked up their teams
34	1	2	User user logged in
35	1	19	User 1 looked up team test_team
36	1	2	User user logged in
37	1	23	User 1 looked up tournaments
38	2	2	User employee logged in
39	2	2	User employee logged in
40	2	2	User employee logged in
41	2	2	User employee logged in
42	0	20	Tournament ID not found
43	1	2	User user logged in
44	1	43	User 1 looked up their tournaments
45	3	2	User manager logged in
46	3	2	User manager logged in
47	3	2	User manager logged in
48	0	12	Payment ID not found
49	3	2	User manager logged in
50	0	12	Payment ID not found
51	3	2	User manager logged in
52	3	25	Item created
53	3	2	User manager logged in
54	3	27	Game created
55	3	2	User manager logged in
56	3	29	Item deleted
57	3	2	User manager logged in
58	3	31	Game deleted
59	3	2	User manager logged in
60	3	33	User mimiced
61	3	2	User manager logged in
62	3	35	User banned
63	0	1	Failed login - User is banned user
64	3	2	User manager logged in
65	3	35	User unbanned
66	1	2	User user logged in
67	1	2	User user logged in
68	1	41	User 1 registered team test_team for tournament test_tournament
69	1	2	User user logged in
70	1	19	User 1 looked up teams
71	1	2	User user logged in
72	1	19	User 1 looked up team test_team
\.


--
-- Data for Name: logtypes; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.logtypes (id, logtype) FROM stdin;
0	Unknown
1	Failed Login Attempt
2	Successful Login Attempt
3	Successful Registration
4	Failed Registration
5	Failed Purchase
6	Successful Purchase
7	Failed to adds funds
8	Funds added successfully
9	Transfer Failed
10	Transfer successful
11	Access denied
12	Payment Modification Failed
13	Payment Modification Successful
14	Team Creation Failed
15	Team Creation Successful
16	Team Join Failed
17	Team Join Successful
18	Team Lookup Failed
19	Team Lookup Successful
20	Tournament Creation Failed
21	Tournament Creation Successful
22	Tournament Cancellation Failed
23	Tournament Cancellation Successful
24	Item Creation Failed
25	Item Creation Successful
26	Game Creation Failed
27	Game Creation Successful
28	Item Deletion Failed
29	Item Deletion Successful
30	Game Deletion Failed
31	Game Deletion Successful
32	User Mimic Failed
33	User Mimic Successful
34	User Ban Failed
35	User Ban Successful
36	Team Leave Failed
37	Team Leave Successful
38	Team Delete Failed
39	Team Delete Successful
40	Tournament Registration Failed
41	Tournament Registration Successful
42	Tournament Lookup Failed
43	Tournament Lookup Successful
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.payments (id, userid, status, amount, external, description, paymentprocessorid) FROM stdin;
e25df61d-2520-4234-94b7-6c071c3db30b	1	1	200.00	f	Added funds to account	\N
588e2657-035c-403d-b341-fbbd81f6f00f	1	2	7.99	f	Purchased Test Item	\N
f9dd6b6f-f0a3-477d-b8ab-24465354497f	1	2	4.99	f	Purchased Test Game	\N
26d527f7-0ba9-4337-a5d8-92ab68f1894d	1	2	100.00	f	Transfer to user2	\N
550fb880-73e0-4636-b0bc-781574cd3c04	4	2	100.00	f	Tranfer from user	\N
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.permissions (permission, bit_no) FROM stdin;
User	0
Employee	1
Manager	2
Admin	3
\.


--
-- Data for Name: statuses; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.statuses (id, message) FROM stdin;
0	Unknown
1	Complete
2	Pending
3	Cancelled
4	Error
5	Open
6	User registered successfully
7	Username already exists
\.


--
-- Data for Name: teamregistrations; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.teamregistrations (id, teamid, userid, joindate) FROM stdin;
1	1	1	2024-01-24 11:50:55.835896
2	1	4	2024-01-24 11:50:55.867273
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.teams (id, name, leaderid) FROM stdin;
1	test_team	1
\.


--
-- Data for Name: tournamentleaderboard; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.tournamentleaderboard (id, tournamentid, teamid, score) FROM stdin;
\.


--
-- Data for Name: tournamentmatches; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.tournamentmatches (id, tournamentid, status) FROM stdin;
\.


--
-- Data for Name: tournamentregistrations; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.tournamentregistrations (id, tournamentid, teamid, joindate) FROM stdin;
1	1	1	2024-01-24 11:52:15.582163
\.


--
-- Data for Name: tournaments; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.tournaments (id, name, starttimestamp, endtimestamp, gameid, status) FROM stdin;
1	test_tournament	2020-01-01 00:00:00	2020-01-01 00:00:00	0	5
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: adminschema; Owner: db_admin
--

COPY adminschema.users (id, username, hash, salt, permissions, balance, token) FROM stdin;
0	System			0	0.00	\N
3	manager	$2a$06$pU9VtK9ZuQ3V5Xnzdax9QebEt94VXhRR6p1eAUSP9z86wZn91Sjgq	$2a$06$pU9VtK9ZuQ3V5Xnzdax9Qe	7	0.00	92c95ce2e19f2426bed60619a35a0a44
1	user	$2a$06$HjwZgPYvxBIxmJGc/zMLZuGCyGE.ms1XSKtro8jSAIGHXQeZCPHXq	$2a$06$HjwZgPYvxBIxmJGc/zMLZu	1	87.01	ada4836ab63c274dfe7db86830ae47c8
4	user2	$2a$06$c.4He72Wyb7O2.89o/ueHOMo746oGp2R11gXE83stBl.skVaMFj/y	$2a$06$c.4He72Wyb7O2.89o/ueHO	1	100.00	8ea44a5d7d4498497cff3026a5df1cdb
2	employee	$2a$06$VFAcqwVGkmps0YXBCOvjIutFYGYyZ4LeFWa/rfnyqm7/3Rxm2B6AW	$2a$06$VFAcqwVGkmps0YXBCOvjIu	3	0.00	2e2dc5274253de4d9e76aa1fef1500db
\.


--
-- Name: communities_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.communities_id_seq', 1, false);


--
-- Name: communityregistrations_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.communityregistrations_id_seq', 1, false);


--
-- Name: gamepurchases_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.gamepurchases_id_seq', 1, true);


--
-- Name: games_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.games_id_seq', 1, true);


--
-- Name: itempurchases_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.itempurchases_id_seq', 1, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.items_id_seq', 1, true);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.logs_id_seq', 72, true);


--
-- Name: logtypes_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.logtypes_id_seq', 1, false);


--
-- Name: statuses_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.statuses_id_seq', 1, false);


--
-- Name: teamregistrations_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.teamregistrations_id_seq', 2, true);


--
-- Name: teams_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.teams_id_seq', 1, true);


--
-- Name: tournamentleaderboard_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.tournamentleaderboard_id_seq', 1, false);


--
-- Name: tournamentmatches_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.tournamentmatches_id_seq', 1, false);


--
-- Name: tournamentregistrations_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.tournamentregistrations_id_seq', 1, true);


--
-- Name: tournaments_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.tournaments_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: adminschema; Owner: db_admin
--

SELECT pg_catalog.setval('adminschema.users_id_seq', 4, true);


--
-- Name: communities communities_name_key; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communities
    ADD CONSTRAINT communities_name_key UNIQUE (name);


--
-- Name: communities communities_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communities
    ADD CONSTRAINT communities_pkey PRIMARY KEY (id);


--
-- Name: communityregistrations communityregistrations_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communityregistrations
    ADD CONSTRAINT communityregistrations_pkey PRIMARY KEY (id);


--
-- Name: gamepurchases gamepurchases_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.gamepurchases
    ADD CONSTRAINT gamepurchases_pkey PRIMARY KEY (id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: itempurchases itempurchases_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.itempurchases
    ADD CONSTRAINT itempurchases_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: logtypes logtypes_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logtypes
    ADD CONSTRAINT logtypes_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: teamregistrations teamregistrations_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teamregistrations
    ADD CONSTRAINT teamregistrations_pkey PRIMARY KEY (id);


--
-- Name: teams teams_name_key; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teams
    ADD CONSTRAINT teams_name_key UNIQUE (name);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tournamentleaderboard tournamentleaderboard_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentleaderboard
    ADD CONSTRAINT tournamentleaderboard_pkey PRIMARY KEY (id);


--
-- Name: tournamentmatches tournamentmatches_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentmatches
    ADD CONSTRAINT tournamentmatches_pkey PRIMARY KEY (id);


--
-- Name: tournamentregistrations tournamentregistrations_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentregistrations
    ADD CONSTRAINT tournamentregistrations_pkey PRIMARY KEY (id);


--
-- Name: tournaments tournaments_name_key; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournaments
    ADD CONSTRAINT tournaments_name_key UNIQUE (name);


--
-- Name: tournaments tournaments_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournaments
    ADD CONSTRAINT tournaments_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: communities communities_adminid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communities
    ADD CONSTRAINT communities_adminid_fkey FOREIGN KEY (adminid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: communityregistrations communityregistrations_communityid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communityregistrations
    ADD CONSTRAINT communityregistrations_communityid_fkey FOREIGN KEY (communityid) REFERENCES adminschema.communities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: communityregistrations communityregistrations_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.communityregistrations
    ADD CONSTRAINT communityregistrations_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gamepurchases gamepurchases_gameid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.gamepurchases
    ADD CONSTRAINT gamepurchases_gameid_fkey FOREIGN KEY (gameid) REFERENCES adminschema.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gamepurchases gamepurchases_paymentid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.gamepurchases
    ADD CONSTRAINT gamepurchases_paymentid_fkey FOREIGN KEY (paymentid) REFERENCES adminschema.payments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: gamepurchases gamepurchases_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.gamepurchases
    ADD CONSTRAINT gamepurchases_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: itempurchases itempurchases_itemid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.itempurchases
    ADD CONSTRAINT itempurchases_itemid_fkey FOREIGN KEY (itemid) REFERENCES adminschema.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: itempurchases itempurchases_paymentid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.itempurchases
    ADD CONSTRAINT itempurchases_paymentid_fkey FOREIGN KEY (paymentid) REFERENCES adminschema.payments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: itempurchases itempurchases_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.itempurchases
    ADD CONSTRAINT itempurchases_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: items items_gameid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.items
    ADD CONSTRAINT items_gameid_fkey FOREIGN KEY (gameid) REFERENCES adminschema.games(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: logs logs_logtype_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logs
    ADD CONSTRAINT logs_logtype_fkey FOREIGN KEY (logtype) REFERENCES adminschema.logtypes(id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: logs logs_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.logs
    ADD CONSTRAINT logs_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: payments payments_status_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.payments
    ADD CONSTRAINT payments_status_fkey FOREIGN KEY (status) REFERENCES adminschema.statuses(id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: payments payments_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.payments
    ADD CONSTRAINT payments_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teamregistrations teamregistrations_teamid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teamregistrations
    ADD CONSTRAINT teamregistrations_teamid_fkey FOREIGN KEY (teamid) REFERENCES adminschema.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teamregistrations teamregistrations_userid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teamregistrations
    ADD CONSTRAINT teamregistrations_userid_fkey FOREIGN KEY (userid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teams teams_leaderid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.teams
    ADD CONSTRAINT teams_leaderid_fkey FOREIGN KEY (leaderid) REFERENCES adminschema.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: tournamentleaderboard tournamentleaderboard_teamid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentleaderboard
    ADD CONSTRAINT tournamentleaderboard_teamid_fkey FOREIGN KEY (teamid) REFERENCES adminschema.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournamentleaderboard tournamentleaderboard_tournamentid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentleaderboard
    ADD CONSTRAINT tournamentleaderboard_tournamentid_fkey FOREIGN KEY (tournamentid) REFERENCES adminschema.tournaments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournamentmatches tournamentmatches_status_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentmatches
    ADD CONSTRAINT tournamentmatches_status_fkey FOREIGN KEY (status) REFERENCES adminschema.statuses(id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: tournamentmatches tournamentmatches_tournamentid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentmatches
    ADD CONSTRAINT tournamentmatches_tournamentid_fkey FOREIGN KEY (tournamentid) REFERENCES adminschema.tournaments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournamentregistrations tournamentregistrations_teamid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentregistrations
    ADD CONSTRAINT tournamentregistrations_teamid_fkey FOREIGN KEY (teamid) REFERENCES adminschema.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournamentregistrations tournamentregistrations_tournamentid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournamentregistrations
    ADD CONSTRAINT tournamentregistrations_tournamentid_fkey FOREIGN KEY (tournamentid) REFERENCES adminschema.tournaments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournaments tournaments_gameid_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournaments
    ADD CONSTRAINT tournaments_gameid_fkey FOREIGN KEY (gameid) REFERENCES adminschema.games(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tournaments tournaments_status_fkey; Type: FK CONSTRAINT; Schema: adminschema; Owner: db_admin
--

ALTER TABLE ONLY adminschema.tournaments
    ADD CONSTRAINT tournaments_status_fkey FOREIGN KEY (status) REFERENCES adminschema.statuses(id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: SCHEMA userschema; Type: ACL; Schema: -; Owner: db_admin
--

GRANT USAGE ON SCHEMA userschema TO db_user;


--
-- PostgreSQL database dump complete
--

