SET search_path = userschema,"$user",public;
-- Register a user
SELECT * FROM register_user('user','user');
--  user login
SELECT * FROM login_user('user','user');
-- Get all items
SELECT * FROM get_items(login_user('user','user'));
-- Get all games
SELECT * FROM get_games(login_user('user','user'));
-- Add funds
SELECT * FROM add_funds(login_user('user','user'),200);
-- Get current balance
SELECT * FROM get_balance(login_user('user','user'));
-- Purchase user item
SELECT * FROM purchase_item(login_user('user','user'),0);
-- Get current items
SELECT * FROM get_my_items(login_user('user','user'));
-- Get current balance
SELECT * FROM get_balance(login_user('user','user'));
-- Purchase game
SELECT * FROM purchase_game(login_user('user','user'),0);
-- Get current games
SELECT * FROM get_my_games(login_user('user','user'));
-- Get current balance
SELECT * FROM get_balance(login_user('user','user'));
-- Get payments
SELECT * FROM get_payments(login_user('user','user'));
-- Create another account
SELECT * FROM register_user('user2','user2');
-- Transfer funds
SELECT * FROM transfer_balance(login_user('user','user'),100,'user2');
-- Get both balances
SELECT * FROM get_balance(login_user('user','user'));
SELECT * FROM get_balance(login_user('user2','user2'));
-- Get teams
SELECT * FROM get_teams(login_user('user','user'));
-- Create a team
SELECT * FROM create_team(login_user('user','user'),'test_team');
-- Get teams
SELECT * FROM get_teams(login_user('user','user'));
-- Join a team
SELECT * FROM join_team(login_user('user2','user2'),'test_team');
-- Get Current teams
SELECT * FROM get_my_teams(login_user('user','user'));
-- Get Specific team
SELECT * FROM get_team(login_user('user','user'),'test_team');
-- Get Tournaments
SELECT * FROM userSchema.get_tournaments(login_user('user','user'));

-- Employee functions
-- Get users
SELECT * FROM userSchema.employee_get_users(login_user('employee','employee'));
-- Get Specific user
SELECT * FROM userSchema.employee_get_users(login_user('employee','employee'),1);
-- Create a tournament
SELECT * FROM userSchema.employee_create_tournament(login_user('employee','employee'),'test_tournament',0,'2020-01-01 00:00:00','2020-01-01 00:00:00');
-- Cancel a tournament
SELECT * FROM userSchema.employee_cancel_tournament(login_user('employee','employee'),0);

-- User functions
-- Join a tournament
SELECT * FROM userSchema.join_tournament(login_user('user','user'),'test_tournament','test_team'),;
-- Get user tournaments
SELECT * FROM userSchema.get_my_tournaments(login_user('user','user'));

-- Manager functions
-- Get logs
SELECT * FROM userSchema.manager_get_logs(login_user('manager','manager'));
-- Get Payments
SELECT * FROM userSchema.manager_get_payments(login_user('manager','manager'));
-- Approve Payments
SELECT * FROM userSchema.manager_approve_payment(login_user('manager','manager'),'9b95a9be-3219-4501-b2df-7405eaebf573');
-- Cancel Payment
SELECT * FROM userSchema.manager_cancel_payment(login_user('manager','manager'),'9b95a9be-3219-4501-b2df-7405eaebf573');
-- Create Item
SELECT * FROM userSchema.manager_create_item(login_user('manager','manager'),'test_item',100,0);
-- Create Game
SELECT * FROM userSchema.manager_create_game(login_user('manager','manager'),'test_game',100.0);
-- Delete Item
SELECT * FROM userSchema.manager_delete_item(login_user('manager','manager'),1);
-- Delete Game
SELECT * FROM userSchema.manager_delete_game(login_user('manager','manager'),1);
-- Mimic a user
SELECT * FROM userSchema.manager_mimic_user(login_user('manager','manager'),'user');
-- Ban a user
SELECT * FROM userSchema.manager_ban_user(login_user('manager','manager'),'user');
-- Test user login
SELECT * FROM login_user('user','user');
-- Unban a user
SELECT * FROM userSchema.manager_unban_user(login_user('manager','manager'),'user');
-- Test user login
SELECT * FROM login_user('user','user');