\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_city';
SELECT is(events.delete_city(1),
          'ERROR: Procedure delete_city is not registered in the procedures table',
          'Procedure delete_city missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_city is not registered in the procedures table',
          'Create log entry for missing delete_city procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_city', '');

-- Test case: city delete with non-existing ID
SELECT is(events.delete_city(-1::integer),
          'ERROR: City "-1" does not exist',
          'delete_city must return error for non-existing city id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: City "-1" does not exist',
          'Create log entry for non-existing city id'
       );

-- Test case: successful city delete
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

SELECT is(events.delete_city((SELECT id FROM events.City WHERE name = 'TestCity')),
          'OK',
          'delete_city must return OK for an existing city'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_city'
       );

-- Check if the city was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.City WHERE name = 'TestCity'),
          '0',
          'City must be deleted from the table'
       );

-- Test case: city delete with related locations
INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

INSERT INTO events.Location (name, city_id, address, latitude, longitude)
VALUES ('TestLocation', (SELECT id FROM events.City WHERE name = 'TestCity'), '', 0.0, 0.0);

SELECT is(events.delete_city((SELECT id FROM events.City WHERE name = 'TestCity')),
          'ERROR: City has related locations',
          'delete_city must return error for city with related locations'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: City has related locations',
          'Create log entry for city with related locations'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;