\c events_database;

-- Create view to show the total number of non-admin users
CREATE VIEW statistics.total_non_admin_users AS
SELECT value
FROM statistics.system_counters
WHERE name = 'non_admin_users';
