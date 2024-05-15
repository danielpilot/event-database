\c statistics_database;

-- Create log table
CREATE TABLE log.Log (
    id SERIAL PRIMARY KEY,
    date TIMESTAMP NOT NULL,
    entry_parameters VARCHAR(255) NOT NULL,
    result VARCHAR(255) NOT NULL
);
