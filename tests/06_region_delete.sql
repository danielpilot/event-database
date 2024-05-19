\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_region';
SELECT is(events.delete_region(1),
          'ERROR: Procedure delete_region is not registered in the procedures table',
          'Procedure delete_region missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_region is not registered in the procedures table',
          'Create log entry for missing delete_region procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_region', '');

-- Test case: region delete with non-existing ID
SELECT is(events.delete_region(-1::integer),
          'ERROR: Region "-1" does not exist',
          'delete_region must return error for non-existing region id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Region "-1" does not exist',
          'Create log entry for non-existing region id'
       );

-- Test case: successful region delete
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

SELECT is(events.delete_region((SELECT id FROM events.Region WHERE name = 'TestRegion')),
          'OK',
          'delete_region must return OK for an existing region'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_region'
       );

-- Check if the region was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.Region WHERE name = 'TestRegion'),
          '0',
          'Region must be deleted from the table'
       );

-- Test case: region delete with related provinces
INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

SELECT is(events.delete_region((SELECT id FROM events.Region WHERE name = 'TestRegion')),
          'ERROR: Region has related provinces',
          'delete_region must return error for region with related provinces'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Region has related provinces',
          'Create log entry for region with related provinces'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;