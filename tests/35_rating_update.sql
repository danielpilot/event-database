\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(13);

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

-- Test case: checking if the update_rating procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'update_rating';
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Procedure update_rating is not registered in the procedures table',
          'Procedure update_rating missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_rating is not registered in the procedures table',
          'Create log entry for missing update_rating procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_rating', '');

-- Test case: updating a rating for a non-existent event
SELECT is(events.update_rating(
                  -1::integer,
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Event "-1" does not exist',
          'update_rating must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: updating a rating with an invalid user
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  -1::integer,
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: User "-1" does not exist',
          'update_rating must return error for non-existent user');

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existent user'
       );

-- Test case: updating a rating with a punctuation greater than 5
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  6::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'update_rating must return error on punctuation greater than 5'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for punctuation greater than 5'
       );

-- Test case: updating a rating with a punctuation smaller than 0
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  6::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'create_rating must return error on punctuation smaller than 0'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for punctuation smaller than 0'
       );

-- Test case: successful rating update
INSERT INTO events.rating(event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
        3,
        'Comment',
        false);

SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  3::smallint,
                  'UpdatedComment',
                  true
          ),
          'OK',
          'update_rating must return OK for a valid rating update'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid rating update'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Rating
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')
             AND punctuation = 3
             AND comment = 'UpdatedComment'
             AND published = true),
          '1',
          'Rating must be updated in the Rating table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;