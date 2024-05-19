\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_region';
SELECT is(events.update_region(1, 'UpdatedRegion', 1::smallint),
          'ERROR: Procedure update_region is not registered in the procedures table',
          'Procedure update_region missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_region is not registered in the procedures table',
          'Create log entry for missing update_region procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_region', '');

-- Test case: region update with non-existing ID
SELECT is(events.update_region(-1::integer, 'UpdatedRegion', 1::smallint),
          'ERROR: Region "-1" does not exist',
          'update_region must return error for non-existing region id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Region "-1" does not exist',
          'Create log entry for non-existing region id'
       );

-- Test case: region update with non-existing country ID
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

SELECT is(events.update_region(
                  (SELECT id FROM events.Region WHERE name = 'TestRegion'),
                  'UpdatedRegion',
                  -1::smallint
          ),
          'ERROR: Country "-1" does not exist',
          'update_region must return error for non-existing country id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country "-1" does not exist',
          'Create log entry for non-existing country id'
       );


-- Test case: successful region update
SELECT is(events.update_region(
                  (SELECT id FROM events.Region WHERE name = 'TestRegion'),
                  'UpdatedRegion',
                  (SELECT id FROM events.Country WHERE name = 'TestCountry')
          ),
          'OK',
          'update_region must return OK for an existing region'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_region'
       );

-- Check if the region was properly updated
SELECT is((SELECT name FROM events.Region WHERE name = 'UpdatedRegion'),
          'UpdatedRegion',
          'Region must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
