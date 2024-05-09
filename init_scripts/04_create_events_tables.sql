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
