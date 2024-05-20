\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_location';
SELECT is(events.delete_location(1::integer),
          'ERROR: Procedure delete_location is not registered in the procedures table',
          'Procedure delete_location missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_location is not registered in the procedures table',
          'Create log entry for missing delete_location procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_location', '');

-- Test case: location delete with non-existing ID
SELECT is(events.delete_location(-1::integer),
          'ERROR: Location "-1" does not exist',
          'delete_location must return error for non-existing location id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Location "-1" does not exist',
          'Create log entry for non-existing location id'
       );

-- Test case: successful location delete
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

SELECT is(events.delete_location((SELECT id FROM events.Location WHERE name = 'TestLocation')),
          'OK',
          'delete_location must return OK for an existing location'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_location'
       );

-- Check if the location was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.Location WHERE name = 'TestLocation'),
          '0',
          'Location must be deleted from the table'
       );

-- Test case: location delete with related events
INSERT INTO events.Location (name, address, city_id, latitude, longitude)
VALUES ('TestLocation', 'TestAddress', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0);

INSERT INTO events.organizer (name, email, type) VALUES ('TestOrganizer', '', 'Company');

INSERT INTO events.Event (name,
                          start_date,
                          end_date,
                          schedule,
                          description,
                          price,
                          event_status,
                          event_published,
                          event_has_sales,
                          comments,
                          organizer_id,
                          location_id)
VALUES ('TestEvent',
        NOW(),
        NOW(),
        '',
        '',
        0.0,
        false,
        false,
        false,
        false,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));

SELECT is(events.delete_location((SELECT id FROM events.Location WHERE name = 'TestLocation')),
          'ERROR: Location has related events',
          'delete_location must return error for location with related events'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Location has related events',
          'Create log entry for location with related events'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;