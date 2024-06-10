\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: Test non-admin users view
UPDATE statistics.system_counters
SET value = 10
WHERE name = 'non_admin_users';

SELECT is((SELECT value::text FROM statistics.total_non_admin_users),
          '10',
          'The total number of non-admin users is correct');

-- Test case: Test average event price view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 1;

SELECT is((SELECT value::text FROM statistics.average_event_price),
          '10',
          'The average event price is correct');

-- Test case: Test average transactions per user view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 2;

SELECT is((SELECT value::text FROM statistics.average_transactions_per_user),
          '10',
          'The average transactions per user is correct');

-- Test case: Test payed events percentage view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 3;

SELECT is((SELECT value::text FROM statistics.payed_events_percentage),
          '10',
          'The payed events percentage is correct');

-- Test case: Test transactions variation view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 5;

SELECT is((SELECT value::text FROM statistics.transactions_variation),
          '10',
          'The transactions variation is correct');

-- Test case: Test average occupation view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 7;

SELECT is((SELECT value::text FROM statistics.average_occupation),
          '10',
          'The average occupation is correct');

-- Test case: Test full events percentage view
UPDATE statistics.percentage_indicators
SET value = 10
WHERE indicator = 8;

SELECT is((SELECT value::text FROM statistics.full_events_percentage),
          '10',
          'The full events percentage is correct');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK
