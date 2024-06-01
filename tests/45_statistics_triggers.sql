\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);
-- Populate database
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user'),
       ('test2', 'test2', 'test2@test.com', 'password2', 'user');

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
VALUES ('TestLocation', 'TestAddress', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0),
       ('TestLocation2', 'TestAddress2', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0);

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
        false,
        true,
        true,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));

-- Test case: add rating that will not be counted for event
INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        5,
        'Test comment',
        false);

SELECT is((SELECT COUNT(*)::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '0',
          'Must not add comment when comment is not published');

-- Test case: add rating that will be counted for event when no ratings exist
DELETE
FROM events.rating
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = ((SELECT id::integer FROM events.User WHERE email = 'test@test.com'));

INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        5,
        'Test comment',
        true);

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '5', '5'],
               'Must add comment when comment is published and ratings not exist'
       );

-- Test case: add rating that will be counted for event when ratings exist
INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test2@test.com'),
        2,
        'Test comment',
        true);

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['2', '3.5', '7'],
               'Must add comment when comment is published and ratings exist'
       );

-- Test case: update and unpublish rating
UPDATE events.rating
SET published = false
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '2', '2'],
               'Must remove comment when comment is unpublished'
       );

-- Test case: update an unpublished rating
UPDATE events.rating
SET punctuation = 3
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '2', '2'],
               'Must keep statistics when unpublished comment is updated'
       );

-- Test case: update statistics when rating is updated to be published
UPDATE events.rating
SET published = true
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['2', '2.5', '5'],
               'Must update statistics when comment is published through update'
       );

-- Test case: update statistics on published event rating update
UPDATE events.rating
SET punctuation = 4
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['2', '3', '6'],
               'Must update statistics when comment rating is updated through update'
       );

-- Test case: update statistics on event delete
DELETE FROM events.rating
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '2', '2'],
               'Must update statistics when comment rating is deleted'
       );

-- Test case: must not update statistics when unpublished comment is deleted
INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        5,
        'Test comment',
        false);

DELETE FROM events.rating
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '2', '2'],
               'Must not update statistics when unpublished comment rating is deleted'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK
