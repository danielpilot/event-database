\c event_database;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO event_user;

-- Create country table
CREATE TABLE Country (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT country_name_unique UNIQUE (name)
);

-- Create region table
CREATE TABLE Region (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_id SMALLINT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES Country(id)
);

-- Create province table
CREATE TABLE Province (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region_id INTEGER NOT NULL,
    FOREIGN KEY (region_id) REFERENCES Region (id)
);

-- Create city table
CREATE TABLE City (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL,
    FOREIGN KEY (province_id) REFERENCES Province (id)
);

-- Create location table
CREATE TABLE Location (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city_id INTEGER NOT NULL,
    address VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    FOREIGN KEY (city_id) REFERENCES City (id)
);

CREATE INDEX idx_location ON Location(latitude, longitude);

-- Create category table
CREATE TABLE Category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    parent_category INTEGER,
    FOREIGN KEY (parent_category) REFERENCES Category(id)
);

-- Create organizer table
CREATE TABLE Organizer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('Company', 'Association', 'Foundation'))
);

-- Create organizer contact table
CREATE TABLE Organizer_Contact (
    name VARCHAR(255) NOT NULL,
    organizer_id INTEGER NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telephone VARCHAR(20),
    PRIMARY KEY (name, organizer_id),
    FOREIGN KEY (organizer_id) REFERENCES Organizer(id)
);

-- Create event table
CREATE TABLE Event (
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
    FOREIGN KEY (organizer_id) REFERENCES Organizer(id),
    FOREIGN KEY (location_id) REFERENCES Location(id)
);

CREATE INDEX idx_start_end_published ON Event(start_date, end_date, event_published);
