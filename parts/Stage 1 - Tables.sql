-- Enables the use of crpt
CREATE EXTENSION pgcrypto;
CREATE EXTENSION "uuid-ossp";

BEGIN;

-- Create initial Schemas
CREATE SCHEMA userSchema;
GRANT USAGE ON SCHEMA userSchema to db_user;
CREATE SCHEMA adminSchema;
GRANT USAGE ON SCHEMA adminSchema to db_admin;

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
    GameID INT REFERENCES adminSchema.Games(ID) ON UPDATE CASCADE ON DELETE CASCADE,
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

COMMIT;