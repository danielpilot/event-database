\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_city';
SELECT is(events.create_city('TestCity', 1),
          'ERROR: Procedure create_city is not registered in the procedures table',
          'Procedure create_city missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_city is not registered in the procedures table',
          'Create log entry for missing create_city procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_city', '');

-- Test case: city creation with non-existing province ID
SELECT is(events.create_city('TestCity', -1::integer),
          'ERROR: Province "-1" does not exist',
          'create_city must return error for non-existing province id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Province "-1" does not exist',
          'Create log entry for non-existing province id'
       );

-- Test case: successful city creation
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

SELECT is(events.create_city('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince')),
          'OK',
          'create_city must return OK for a valid province'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_city'
       );

-- Check if the city was properly created
SELECT is((SELECT name FROM events.City WHERE name = 'TestCity'),
          'TestCity',
          'City must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
