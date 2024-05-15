\c event_database;

-- Create country table
CREATE TABLE events.Country (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT country_name_unique UNIQUE (name)
) TABLESPACE operational_tablespace;

-- Create region table
CREATE TABLE events.Region (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_id SMALLINT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES events.Country(id)
) TABLESPACE operational_tablespace;

-- Create province table
CREATE TABLE events.Province (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region_id INTEGER NOT NULL,
    FOREIGN KEY (region_id) REFERENCES events.Region (id)
) TABLESPACE operational_tablespace;

-- Create city table
CREATE TABLE events.City (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL,
    FOREIGN KEY (province_id) REFERENCES events.Province (id)
) TABLESPACE operational_tablespace;

-- Create location table
CREATE TABLE events.Location (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city_id INTEGER NOT NULL,
    address VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    FOREIGN KEY (city_id) REFERENCES events.City (id)
) TABLESPACE operational_tablespace;

CREATE INDEX idx_location ON events.Location(latitude, longitude);

-- Create category table
CREATE TABLE events.Category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    parent_category INTEGER,
    FOREIGN KEY (parent_category) REFERENCES events.Category(id) ON DELETE SET NULL,
    UNIQUE (name, parent_category)
) TABLESPACE operational_tablespace;

-- Create organizer table
CREATE TABLE events.Organizer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('Company', 'Association', 'Foundation'))
) TABLESPACE operational_tablespace;

-- Create organizer contact table
CREATE TABLE events.Organizer_Contact (
    name VARCHAR(255) NOT NULL,
    organizer_id INTEGER NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telephone VARCHAR(20),
    PRIMARY KEY (name, organizer_id),
    FOREIGN KEY (organizer_id) REFERENCES events.Organizer(id) ON DELETE CASCADE
) TABLESPACE operational_tablespace;

-- Create event table
CREATE TABLE events.Event (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    schedule VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price REAL NOT NULL,
    image VARCHAR(255),
    event_status BOOLEAN NOT NULL,
    event_published BOOLEAN NOT NULL,
    comments BOOLEAN NOT NULL,
    organizer_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    FOREIGN KEY (organizer_id) REFERENCES events.Organizer(id),
    FOREIGN KEY (location_id) REFERENCES events.Location(id)
) TABLESPACE operational_tablespace;

CREATE INDEX idx_start_end_published ON events.Event(start_date, end_date, event_published);

-- Create event with sales function
CREATE TABLE events.Event_With_Sales (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    capacity SMALLINT NOT NULL,
    maximum_per_sale SMALLINT NOT NULL,
    FOREIGN KEY (event_id) REFERENCES events.Event(id)
) TABLESPACE operational_tablespace;

-- Create event category relation table
CREATE TABLE events.Event_Has_Category (
    event_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (event_id, category_id),
    FOREIGN KEY (event_id) REFERENCES events.Event(id),
    FOREIGN KEY (category_id) REFERENCES events.Category(id)
) TABLESPACE operational_tablespace;

-- Create event change table
CREATE TABLE events.Event_Change (
    id SERIAL NOT NULL,
    event_id INTEGER NOT NULL,
    type VARCHAR(30) NOT NULL CHECK ( type IN ('Delayed', 'Cancelled', 'Location Change', 'Price Change', 'Other') ),
    date TIMESTAMP NOT NULL,
    description TEXT NOT NULL,
    PRIMARY KEY (id, event_id),
    FOREIGN KEY (event_id) REFERENCES events.Event(id)
) TABLESPACE operational_tablespace;

-- Create user table
CREATE TABLE events.User (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    roles VARCHAR(255) NOT NULL
) TABLESPACE operational_tablespace;

-- Create user event favorite table
CREATE TABLE events.Event_Favorite (
    event_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events.Event(id),
    FOREIGN KEY (user_id) REFERENCES events.User(id)
) TABLESPACE operational_tablespace;

-- Create rating table
CREATE TABLE events.Rating (
    event_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    punctuation SMALLINT NOT NULL,
    comment TEXT NOT NULL,
    published BOOLEAN NOT NULL,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events.Event(id),
    FOREIGN KEY (user_id) REFERENCES events.User(id)
) TABLESPACE operational_tablespace;

CREATE TABLE events.Transaction (
    event_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    quantity SMALLINT NOT NULL,
    reference VARCHAR(5) NOT NULL UNIQUE,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events.Event(id),
    FOREIGN KEY (user_id) REFERENCES events.User(id)
) TABLESPACE operational_tablespace;
