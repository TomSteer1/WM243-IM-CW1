CREATE OR REPLACE VIEW adminSchema.list_users
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

