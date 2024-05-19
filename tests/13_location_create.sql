\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_location';
SELECT is(events.create_location('TestLocation', '', 1::integer, 0.0, 0.0),
          'ERROR: Procedure create_location is not registered in the procedures table',
          'Procedure create_location missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_location is not registered in the procedures table',
          'Create log entry for missing create_location procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_location', '');

-- Test case: location creation with non-existing city ID
SELECT is(events.create_location('TestLocation', 'TestAddress', -1::integer, 0.0, 0.0),
          'ERROR: City "-1" does not exist',
          'create_location must return error for non-existing city id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: City "-1" does not exist',
          'Create log entry for non-existing city id'
       );

-- Test case: successful location creation
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

SELECT is(events.create_location(
                  'TestLocation',
                  'TestAddress',
                  (SELECT id FROM events.City WHERE name = 'TestCity'),
                  0.0,
                  0.0
          ),
          'OK',
          'create_location must return OK for a valid city'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_location'
       );

-- Check if the location was properly created
SELECT is((SELECT name FROM events.Location WHERE name = 'TestLocation'),
          'TestLocation',
          'Location must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;