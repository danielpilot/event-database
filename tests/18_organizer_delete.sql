\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_organizer';
SELECT is(events.delete_organizer(1::integer),
          'ERROR: Procedure delete_organizer is not registered in the procedures table',
          'Procedure delete_organizer missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_organizer is not registered in the procedures table',
          'Create log entry for missing delete_organizer procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_organizer', '');

-- Test case: organizer delete with non-existing ID
SELECT is(events.delete_organizer(-1::integer),
          'ERROR: Organizer "-1" does not exist',
          'delete_organizer must return error for non-existing organizer id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer "-1" does not exist',
          'Create log entry for non-existing organizer id'
       );

-- Test case: successful organizer delete
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

SELECT is(events.delete_organizer((SELECT id FROM events.organizer WHERE name = 'TestOrganizer')),
          'OK',
          'delete_organizer must return OK for an existing organizer'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_organizer'
       );

-- Check if the organizer was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.organizer WHERE name = 'TestOrganizer'),
          '0',
          'Organizer must be deleted from the table'
       );

-- Test case: organizer delete with related events
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

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

SELECT is(events.delete_organizer((SELECT id FROM events.organizer WHERE name = 'TestOrganizer')),
          'ERROR: Organizer has related events',
          'delete_organizer must return error for organizer with related events'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer has related events',
          'Create log entry for organizer with related events'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;