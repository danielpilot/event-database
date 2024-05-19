\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_region';
SELECT is(events.create_region('TestRegion', 1::smallint),
          'ERROR: Procedure create_region is not registered in the procedures table',
          'Procedure create_region missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_region is not registered in the procedures table',
          'Create log entry for missing create_region procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_region', '');

-- Test case: region creation with non-existing country ID
SELECT is(events.create_region('TestRegion', -1::smallint),
          'ERROR: Country "-1" does not exist',
          'create_region must return error for non-existing country id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country "-1" does not exist',
          'Create log entry for non-existing country id'
       );

-- Test case: successful region creation
INSERT INTO events.Country (name)
VALUES ('TestCountry');

SELECT is(events.create_region('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry')),
          'OK',
          'create_region must return OK for a valid country'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_region'
       );

SELECT is((SELECT name FROM events.Region WHERE name = 'TestRegion'),
          'TestRegion',
          'Region must be added to the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
