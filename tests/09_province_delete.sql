\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_province';
SELECT is(events.delete_province(1),
          'ERROR: Procedure delete_province is not registered in the procedures table',
          'Procedure delete_province missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_province is not registered in the procedures table',
          'Create log entry for missing delete_province procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_province', '');

-- Test case: province delete with non-existing ID
SELECT is(events.delete_province(-1::integer),
          'ERROR: Province "-1" does not exist',
          'delete_province must return error for non-existing province id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Province "-1" does not exist',
          'Create log entry for non-existing province id'
       );

-- Test case: successful province delete
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

SELECT is(events.delete_province((SELECT id FROM events.Province WHERE name = 'TestProvince')),
          'OK',
          'delete_province must return OK for an existing province'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_province'
       );

-- Check if the province was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.Province WHERE name = 'TestProvince'),
          '0',
          'Province must be deleted from the table'
       );

-- Test case: province delete with related cities
INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

SELECT is(events.delete_province((SELECT id FROM events.Province WHERE name = 'TestProvince')),
          'ERROR: Province has related cities',
          'delete_province must return error for province with related cities'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Province has related cities',
          'Create log entry for province with related cities'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
