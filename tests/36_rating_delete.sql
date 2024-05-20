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

-- Test case: checking if the delete_rating procedure is registered in the procedures table
DELETE FROM logs.Procedure WHERE name = 'delete_rating';
SELECT is(events.delete_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1)
          ),
          'ERROR: Procedure delete_rating is not registered in the procedures table',
          'Procedure delete_rating missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_rating is not registered in the procedures table',
          'Create log entry for missing delete_rating procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_rating', '');

-- Test case: deleting a non-existent rating
SELECT is(events.delete_rating(-1::integer,
                  -1::integer
          ),
          'ERROR: Rating for event "-1" and user "-1" does not exist',
          'delete_rating must return error for non-existent rating'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Rating for event "-1" and user "-1" does not exist',
          'Create log entry for non-existent rating'
       );

-- Test case: successful rating deletion
INSERT INTO events.rating(event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
        3,
        'Comment',
        false);

SELECT is(events.delete_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1)
          ),
          'OK',
          'delete_rating must return OK for a valid rating deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid rating deletion'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Rating
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '0',
          'Rating must be deleted from the Rating table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
