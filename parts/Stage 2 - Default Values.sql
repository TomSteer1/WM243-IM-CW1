BEGIN;

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

COMMIT;