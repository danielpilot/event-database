\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_province';
SELECT is(events.create_province('TestProvince', 1),
          'ERROR: Procedure create_province is not registered in the procedures table',
          'Procedure create_province missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_province is not registered in the procedures table',
          'Create log entry for missing create_province procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_province', '');

-- Test case: province creation with non-existing region ID
SELECT is(events.create_province('TestProvince', -1::integer),
          'ERROR: Region "-1" does not exist',
          'create_province must return error for non-existing region id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Region "-1" does not exist',
          'Create log entry for non-existing region id'
       );

-- Test case: successful province creation
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

SELECT is(events.create_province(
                  'TestProvince',
                  (SELECT id FROM events.Region WHERE name = 'TestRegion')
          ),
          'OK',
          'create_province must return OK for a valid region'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_province'
       );

-- Check if the province was properly created
SELECT is((SELECT name FROM events.Province WHERE name = 'TestProvince'),
          'TestProvince',
          'Province must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
