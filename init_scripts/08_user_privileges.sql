\c event_database;

GRANT ALL PRIVILEGES ON SCHEMA events TO event_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA events TO event_user;

GRANT ALL PRIVILEGES ON SCHEMA statistics TO statistics_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA statistics TO statistics_user;

GRANT ALL PRIVILEGES ON SCHEMA logs TO log_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA logs TO log_user;
