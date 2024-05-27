\c event_database;

-- Create city statistics table
CREATE TABLE statistics.City_Statistics
(
    city_id INTEGER PRIMARY KEY,
    events  INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create location statistics table
CREATE TABLE statistics.Location_Statistics
(
    location_id INTEGER PRIMARY KEY,
    events      INTEGER
) TABLESPACE warehouse_tablespace;

-- Create event statistics table
CREATE TABLE statistics.Event_Statistics
(
    event_id       INTEGER PRIMARY KEY,
    ratings_count  INTEGER NOT NULL DEFAULT 0,
    average_rating REAL    NOT NULL DEFAULT 0.0,
    total_rating   INTEGER NOT NULL DEFAULT 0,
    sales          INTEGER NOT NULL DEFAULT 0,
    occupancy      REAL    NOT NULL DEFAULT 0.0
) TABLESPACE warehouse_tablespace;

-- Create transaction statistics table
CREATE TABLE statistics.Transaction_Statistics
(
    month        SMALLINT NOT NULL,
    year         SMALLINT NOT NULL,
    transactions INTEGER  NOT NULL,
    PRIMARY KEY (month, year)
) TABLESPACE warehouse_tablespace;

-- Create event with sale statistics table
CREATE TABLE statistics.Event_With_Sale_Statistics
(
    event_id  INTEGER PRIMARY KEY,
    price     REAL    NOT NULL,
    sells     INTEGER NOT NULL,
    occupancy REAL    NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create system counters table
CREATE TABLE statistics.System_Counters
(
    name  VARCHAR(30) PRIMARY KEY,
    value INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create integer indicators table
CREATE TABLE statistics.Integer_Indicators
(
    indicator SMALLINT PRIMARY KEY CHECK ( indicator IN ('1') ),
    value     INTEGER NOT NULL
) TABLESPACE warehouse_tablespace;

-- Create percentage indicators table
CREATE TABLE statistics.Percentage_Indicators
(
    indicator SMALLINT PRIMARY KEY CHECK ( indicator in ('1', '2', '3', '4', '5', '6', '7')),
    value     REAL NOT NULL
) TABLESPACE warehouse_tablespace;
