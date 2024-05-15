\c event_database;

-- Create procedure list table
CREATE TABLE logs.Procedures (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL
);

-- Create log table
CREATE TABLE logs.Log (
    id BIGSERIAL PRIMARY KEY,
    date TIMESTAMP NOT NULL,
    db_user VARCHAR(255) NOT NULL,
    procedure_id INTEGER NOT NULL,
    entry_parameters TEXT NOT NULL,
    result TEXT NOT NULL,
    FOREIGN KEY (procedure_id) REFERENCES logs.Procedures(id)
) TABLESPACE operational_tablespace;
