\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

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

-- Test case: checking if the create_event_favorite procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'create_event_favorite';
SELECT is(events.create_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1)
          ),
          'ERROR: Procedure create_event_favorite is not registered in the procedures table',
          'Procedure create_event_favorite missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_event_favorite is not registered in the procedures table',
          'Create log entry for missing create_event_favorite procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_event_favorite', '');

-- Test case: creating a favorite for a non-existent event
SELECT is(events.create_event_favorite(
                  -1::integer,
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com')
          ),
          'ERROR: Event "-1" does not exist',
          'create_event_favorite must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: creating a favorite for a non-existent user
SELECT is(events.create_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent'),
                  -1::integer
          ),
          'ERROR: User "-1" does not exist',
          'create_event_favorite must return error for non-existent user'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existent user'
       );

-- Test case: creating a favorite successfully
SELECT is(events.create_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent'),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com')
          ),
          'OK',
          'create_event_favorite must return OK for a valid favorite creation'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for favorite creation'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.event_favorite
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent')
             AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com')),
          '1',
          'Favorite must be created in the Event_Favorite table'
       );

-- Test case: creating a favorite that already exists
SELECT is(events.create_event_favorite(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent'),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com')
          ),
          'ERROR: Favorite already exists',
          'create_event_favorite must return error for favorite that already exists'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Favorite already exists',
          'Create log entry for favorite that already exists'
       );

