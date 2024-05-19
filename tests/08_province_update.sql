\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_province';
SELECT is(events.update_province(1, 'UpdatedProvince', 1::integer),
          'ERROR: Procedure update_province is not registered in the procedures table',
          'Procedure update_province missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_province is not registered in the procedures table',
          'Create log entry for missing update_province procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_province', '');

-- Test case: province update with non-existing ID
SELECT is(events.update_province(-1::integer, 'UpdatedProvince', 1::integer),
          'ERROR: Province "-1" does not exist',
          'update_province must return error for non-existing province id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Province "-1" does not exist',
          'Create log entry for non-existing province id'
       );

-- Test case: province update with non-existing region ID
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

SELECT is(events.update_province(
                  (SELECT id FROM events.Province WHERE name = 'TestProvince'),
                  'UpdatedProvince',
                  -1::integer
          ),
          'ERROR: Region "-1" does not exist',
          'update_province must return error for non-existing region id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Region "-1" does not exist',
          'Create log entry for non-existing region id'
       );

-- Test case: successful province update
SELECT is(events.update_province(
                  (SELECT id FROM events.Province WHERE name = 'TestProvince'),
                  'UpdatedProvince',
                  (SELECT id FROM events.Region WHERE name = 'TestRegion')
          ),
          'OK',
          'update_province must return OK for an existing province'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_province'
       );

-- Check if the province was properly updated
SELECT is((SELECT name FROM events.Province WHERE name = 'UpdatedProvince'),
          'UpdatedProvince',
          'Province must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
