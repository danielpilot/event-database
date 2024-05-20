\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_location';
SELECT is(events.update_location(
                  1,
                  'UpdatedLocation',
                  'UpdatedAddress',
                  1::integer,
                  0.0,
                  0.0
          ),
          'ERROR: Procedure update_location is not registered in the procedures table',
          'Procedure update_location missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_location is not registered in the procedures table',
          'Create log entry for missing update_location procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_location', '');

-- Test case: location update with non-existing ID
SELECT is(events.update_location(
                  -1::integer,
                  'UpdatedLocation',
                  'UpdatedAddress',
                  1::integer,
                  0.0,
                  0.0
          ),
          'ERROR: Location "-1" does not exist',
          'update_location must return error for non-existing location id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Location "-1" does not exist',
          'Create log entry for non-existing location id'
       );

-- Test case: location update with non-existing city ID
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

INSERT INTO events.Location (name, address, city_id, latitude, longitude)
VALUES ('TestLocation', 'TestAddress', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0);

SELECT is(events.update_location(
                  (SELECT id FROM events.Location WHERE name = 'TestLocation'),
                  'UpdatedLocation',
                  'UpdatedAddress',
                  -1::integer,
                  0.0,
                  0.0
          ),
          'ERROR: City "-1" does not exist',
          'update_location must return error for non-existing city id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: City "-1" does not exist',
          'Create log entry for non-existing city id'
       );

-- Test case: successful location update
SELECT is(events.update_location(
                  (SELECT id FROM events.Location WHERE name = 'TestLocation'),
                  'UpdatedLocation',
                  'UpdatedAddress',
                  (SELECT id FROM events.City WHERE name = 'TestCity'),
                  0.0,
                  0.0
          ),
          'OK',
          'update_location must return OK for an existing location'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_location'
       );

-- Check if the location was properly updated
SELECT is((SELECT name FROM events.Location WHERE name = 'UpdatedLocation'),
          'UpdatedLocation',
          'Location must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
