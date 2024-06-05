\c event_database;

-- Create view to show the total number of non-admin users
CREATE VIEW statistics.total_non_admin_users AS
SELECT value
FROM statistics.system_counters
WHERE name = 'non_admin_users';

-- Create view to show the average number of transactions per user
CREATE VIEW statistics.average_transactions_per_user AS
SELECT value
FROM statistics.percentage_indicators
WHERE indicator = 2;
