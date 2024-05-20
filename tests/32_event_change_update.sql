\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

-- Test case: checking if the update_event_change procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'update_event_change';
SELECT is(events.update_event_change(
                  (SELECT id::integer
                   FROM events.Event_Change
                   WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  'TestType',
                  'TestDescription'
          ),
          'ERROR: Procedure update_event_change is not registered in the procedures table',
          'Procedure update_event_change missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_event_change is not registered in the procedures table',
          'Create log entry for missing update_event_change procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_event_change', '');

-- Test case: updating an event change for a non-existent event
SELECT is(events.update_event_change(
                  -1::integer,
                  -1::integer,
                  'Other',
                  'TestDescription'
          ),
          'ERROR: Event change "-1" does not exist',
          'update_event_change must return error for non-existent event change'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event change "-1" does not exist',
          'Create log entry for non-existent event change'
       );

-- Test case: updating an event with an invalid event
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

INSERT INTO events.event_change(event_id, type, date, description)
VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'), 'Other', NOW(), 'TestDescription');

SELECT is(events.update_event_change(
                  (SELECT id::integer
                   FROM events.Event_Change
                   WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  -1::integer,
                  'Other',
                  'TestDescription'
          ),
          'ERROR: Event "-1" does not exist',
          'update_event_change must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: updating an event change with an invalid type
SELECT is(events.update_event_change(
                  (SELECT id::integer
                   FROM events.Event_Change
                   WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  'InvalidType',
                  'TestDescription'
          ),
          'ERROR: Invalid event change type "InvalidType"',
          'update_event_change must return error for invalid type');

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Invalid event change type "InvalidType"',
          'Create log entry for invalid type'
       );

-- Test case: successful event change update
SELECT is(events.update_event_change(
                  (SELECT id::integer
                   FROM events.Event_Change
                   WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  'Delayed',
                  'Description'
          ),
          'OK',
          'update_event_change must return OK for a valid event change update'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event change update'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Event_change
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent' AND type = 'Delayed')),
          '1',
          'Event change must be updated in the Event_Change table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;