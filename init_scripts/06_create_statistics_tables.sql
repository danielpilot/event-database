\c event_database;

-- Create city statistics table
CREATE TABLE statistics.City_Statistics (
    city_id INTEGER PRIMARY KEY,
    events INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create location statistics table
CREATE TABLE statistics.Location_Statistics (
    location_id INTEGER PRIMARY KEY,
    events INTEGER
) TABLESPACE warehouse_tablespace;

-- Create event statistics table
CREATE TABLE statistics.Event_Statistics (
    event_id INTEGER PRIMARY KEY,
    comments INTEGER NOT NULL,
    average_rating REAL NOT NULL,
    sales INTEGER NOT NULL,
    occupancy REAL NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create transaction statistics table
CREATE TABLE statistics.Transaction_Statistics (
    month SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    transactions INTEGER NOT NULL,
    PRIMARY KEY (month, year)
) TABLESPACE warehouse_tablespace;

-- Create event with sale statistics table
CREATE TABLE statistics.Event_With_Sale_Statistics (
    event_id INTEGER PRIMARY KEY,
    price REAL NOT NULL,
    sells INTEGER NOT NULL,
    occupancy REAL NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create system counters table
CREATE TABLE statistics.System_Counters (
    name VARCHAR(30) PRIMARY KEY,
    value INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create top valued events table
CREATE TABLE statistics.Top_Valued_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create top sold events table
CREATE TABLE statistics.Top_Sold_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create top event locations table
CREATE TABLE statistics.Top_Event_Locations (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create top favorite events table
CREATE TABLE statistics.Top_Favorite_Events (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create integer indicators table
CREATE TABLE statistics.Integer_Indicators (
    indicator SMALLINT PRIMARY KEY CHECK ( indicator IN ('1') ),
    value INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create percentage indicators table
CREATE TABLE statistics.Percentage_Indicators (
    indicator SMALLINT PRIMARY KEY CHECK ( indicator in ('1', '2', '3', '4', '5', '6', '7')),
    value REAL NOT NULL
) TABLESPACE warehouse_tablespace;
