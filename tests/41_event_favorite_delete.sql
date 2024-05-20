\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Populate database
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user');
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

-- Test case: checking if the delete_event_favorite procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'delete_event_favorite';
SELECT is(events.delete_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1)
          ),
          'ERROR: Procedure delete_event_favorite is not registered in the procedures table',
          'Procedure delete_event_favorite missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_event_favorite is not registered in the procedures table',
          'Create log entry for missing delete_event_favorite procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_event_favorite', '');

-- Test case: deleting a favorite that does not exist
SELECT is(events.delete_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test2@test.com')
          ),
          'ERROR: Favorite does not exist',
          'delete_event_favorite must return error for favorite that does not exist'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Favorite does not exist',
          'Create log entry for favorite that does not exist'
       );

-- Test case: successful favorite deletion
INSERT INTO events.event_favorite (event_id, user_id)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent'),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'));

SELECT is(events.delete_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent'),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com')
          ),
          'OK',
          'delete_event_favorite must return OK for valid favorite deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid favorite deletion'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.event_favorite
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
             AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com')),
          '0',
          'Favorite must be deleted from the Event_Favorite table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
