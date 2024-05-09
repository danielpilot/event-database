\c statistics_database;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO statistics_user;

-- Create city statistics table
CREATE TABLE City_Statistics (
    city_id INTEGER PRIMARY KEY,
    events INTEGER NOT NULL
);

-- Create location statistics table
CREATE TABLE Location_Statistics (
    location_id INTEGER PRIMARY KEY,
    events INTEGER
);

-- Create event statistics table
CREATE TABLE Event_Statistics (
    event_id INTEGER PRIMARY KEY,
    comments INTEGER NOT NULL,
    average_rating REAL NOT NULL,
    sales INTEGER NOT NULL,
    occupancy REAL NOT NULL
);

-- Create transaction statistics table
CREATE TABLE Transaction_Statistics (
    month SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    transactions INTEGER NOT NULL,
    PRIMARY KEY (month, year)
);

-- Create event with sale statistics table
CREATE TABLE Event_With_Sale_Statistics (
    event_id INTEGER PRIMARY KEY,
    price REAL NOT NULL,
    sells INTEGER NOT NULL,
    occupancy REAL NOT NULL
);

-- Create system counters table
CREATE TABLE System_Counters (
    name VARCHAR(30) PRIMARY KEY,
    value INTEGER NOT NULL
);

-- Create top valued events table
CREATE TABLE Top_Valued_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create top sold events table
CREATE TABLE Top_Sold_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create top event locations table
CREATE TABLE Top_Event_Locations (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create top favorite events table
CREATE TABLE Top_Favorite_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create integer indicators table
CREATE TABLE Integer_Indicators (
    indicator SMALLINT PRIMARY KEY CHECK ( indicator IN ('1') ),
    value INTEGER NOT NULL
);

-- Create percentage indicators table
CREATE TABLE Percentage_Indicators (
    indicator SMALLINT PRIMARY KEY CHECK ( indicator in ('1', '2', '3', '4', '5', '6', '7')),
    value REAL NOT NULL
);
