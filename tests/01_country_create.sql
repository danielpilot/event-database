\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(8);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_country';

SELECT is(events.create_country('TestCountry'),
          'ERROR: Procedure create_country is not registered in the procedures table',
          'Procedure create_country missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_country is not registered in the procedures table',
          'Create log entry for missing create_country procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_country', '');


-- Test case: successful country creation
SELECT is(events.create_country('TestCountry'),
          'OK',
          'create_country must return OK for a new country'
       );

SELECT is((SELECT name FROM events.country ORDER BY id DESC LIMIT 1),
          'TestCountry',
          'create_country must insert country in database'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_country'
       );

-- Test case: duplicate country creation
SELECT COUNT(*) AS countries_count_before_add_duplicate_operation
INTO temp_create_count_before
FROM events.country;

SELECT is(events.create_country('TestCountry'),
          'ERROR: Country with name "TestCountry" already exists',
          'create_country must return error for duplicate entry'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country with name "TestCountry" already exists',
          'Create log entry for create_country on duplicate key'
       );

SELECT COUNT(*) AS countries_count_after_add_duplicate_operation
INTO temp_create_count_after
FROM events.country;

SELECT is((SELECT countries_count_before_add_duplicate_operation FROM temp_create_count_before),
          (SELECT countries_count_after_add_duplicate_operation FROM temp_create_count_after),
          'Duplicate name must not add new entry'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
