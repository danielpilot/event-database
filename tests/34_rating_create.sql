\c event_database;

SET SEARCH_PATH TO public, events;

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

-- Begin tests
BEGIN;
SELECT plan(13);

-- Test case: checking if the create_rating procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'create_rating';
SELECT is(events.create_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  5::smallint,
                  'TestComment',
                  true
          ),
          'ERROR: Procedure create_rating is not registered in the procedures table',
          'Procedure create_rating missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_rating is not registered in the procedures table',
          'Create log entry for missing create_rating procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_rating', '');

-- Test case: creating a rating for a non-existent event
SELECT is(events.create_rating(
                  -1::integer,
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  5::smallint,
                  'TestComment',
                  true
          ),
          'ERROR: Event "-1" does not exist',
          'create_rating must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: creating a rating with an invalid user
SELECT is(events.create_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  -1::integer,
                  5::smallint,
                  'TestComment',
                  true
          ),
          'ERROR: User "-1" does not exist',
          'create_rating must return error for non-existent user');

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existent user'
       );

-- Test case: creating a rating with a punctuation greater than 5
SELECT is(events.create_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  6::smallint,
                  'TestComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'create_rating must return error on punctuation greater than 5'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for valid rating creation'
       );

-- Test case: creating a rating with a punctuation smaller than 0
SELECT is(events.create_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  -1::smallint,
                  'TestComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'create_rating must return error on punctuation greater than 5'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for valid rating creation'
       );

-- Test case: successful rating creation
SELECT is(events.create_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  5::smallint,
                  'TestComment',
                  true
          ),
          'OK',
          'create_rating must return OK for a valid rating creation'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid rating creation'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Rating
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '1',
          'Rating must be created in the Rating table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;