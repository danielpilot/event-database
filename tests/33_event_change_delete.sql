\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: checking if the delete_event_change procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'delete_event_change';
SELECT is(events.delete_event_change(1::integer),
          'ERROR: Procedure delete_event_change is not registered in the procedures table',
          'Procedure delete_event_change missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_event_change is not registered in the procedures table',
          'Create log entry for missing delete_event_change procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_event_change', '');

-- Test case: deleting an event change for a non-existent event change
SELECT is(events.delete_event_change(-1::integer),
          'ERROR: Event change "-1" does not exist',
          'delete_event_change must return error for non-existent event change'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event change "-1" does not exist',
          'Create log entry for non-existent event change'
       );

-- Test case: successful event change deletion
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
        true,
        true,
        true,
        true,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));


WITH ec AS (
    INSERT INTO events.event_change (event_id, type, date, description)
        VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'), 'Other', NOW(), 'TestDescription') RETURNING id)

SELECT is(events.delete_event_change(
                      (SELECT id FROM ec)
          ),
          'OK',
          'delete_event_change must return OK for a valid event change deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event change deletion'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Event_change
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '0',
          'Event change must be deleted from the Event_Change table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
