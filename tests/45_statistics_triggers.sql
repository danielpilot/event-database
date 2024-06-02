\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(49);
-- Populate database
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user'),
       ('test2', 'test2', 'test2@test.com', 'password2', 'user'),
       ('test3', 'test3', 'test3@test.com', 'password3', 'user');

INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince')),
       ('TestCity2', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

INSERT INTO events.Location (name, address, city_id, latitude, longitude)
VALUES ('TestLocation', 'TestAddress', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0),
       ('TestLocation2', 'TestAddress2', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0),
       ('TestLocation3', 'TestAddress3', (SELECT id FROM events.City WHERE name = 'TestCity2'), 0.0, 0.0);

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
        (SELECT id FROM events.Location WHERE name = 'TestLocation')),
       ('TestEvent2',
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
        (SELECT id FROM events.Location WHERE name = 'TestLocation2'));

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
DELETE
FROM events.rating
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

DELETE
FROM events.rating
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test@test.com');

SELECT results_eq(
               'SELECT unnest(ARRAY[ratings_count::text, average_rating::text, total_rating::text])
                FROM statistics.event_statistics
                WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = ''TestEvent'' LIMIT 1)',
               ARRAY ['1', '2', '2'],
               'Must not update statistics when unpublished comment rating is deleted'
       );

-- Test case: must create statistics when new favorite is published
DELETE
FROM statistics.event_statistics
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1);

INSERT INTO events.event_favorite (event_id, user_id)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'));

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '1',
          'Must add favorite when first favorite is published');

-- Test case: must increment statistics when new favorite is published
INSERT INTO events.event_favorite (event_id, user_id)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test2@test.com'));

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '2',
          'Must add favorite when favorite is published');

-- Test case: must keep statistics when favorite user is updated
UPDATE events.event_favorite
SET user_id = (SELECT id::integer FROM events.User WHERE email = 'test3@test.com')
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test2@test.com');

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '2',
          'Must keep statistics when favorite user is updated');

-- Test case: must update statistics when favorite event is changed
UPDATE events.event_favorite
SET event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1)
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test3@test.com');

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '1',
          'Must decrease statistics when favorite event is updated');

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1)),
          '1',
          'Must increase statistics when favorite event is updated');

-- Test case: must decrease statistics when favorite is deleted
DELETE
FROM events.event_favorite
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1)
  AND user_id = (SELECT id::integer FROM events.User WHERE email = 'test3@test.com');

SELECT is((SELECT favorites::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1)),
          '0',
          'Must decrease statistics when favorite event is deleted');

-- Test case: must have not create statistics on unpublished event creation
SELECT is((SELECT COUNT(*)::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '0',
          'Must have not create statistics on unpublished event creation');

SELECT is((SELECT COUNT(*)::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '0',
          'Must have not created statistics for city when unpublished event was created');

-- Test case: must have not create statistics on cancelled event creation
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
VALUES ('TestEvent3',
        NOW(),
        NOW(),
        '',
        '',
        0.0,
        false,
        true,
        true,
        true,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));

SELECT is((SELECT COUNT(*)::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '0',
          'Must have not create statistics on cancelled event creation');

SELECT is((SELECT COUNT(*)::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '0',
          'Must have not created statistics for city when cancelled event was created');

-- Test case: must create statistics when event is created
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
VALUES ('TestEvent4',
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

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '1',
          'Must create statistics for location when event is created');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '1',
          'Must create statistics for city when event is created');

-- Test case: must increase statistics when event is created
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
VALUES ('TestEvent5',
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

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '2',
          'Must increase statistics for location when event is created');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '2',
          'Must increase statistics for city when event is created');

-- Test case: must increase statistics when unpublished event gets published
UPDATE events.Event
SET event_published = true
WHERE name = 'TestEvent';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '3',
          'Must increase statistics for location when event is published');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '3',
          'Must increase statistics for city when event is published');

-- Test case: must increase statistics when unpublished event gets programmed
UPDATE events.Event
SET event_status = true
WHERE name = 'TestEvent3';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '3',
          'Must increase statistics for location when event is programmed');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '3',
          'Must increase statistics for city when event is programmed');

-- Test case: must decrease statistics when published event gets unpublished
UPDATE events.Event
SET event_published = false
WHERE name = 'TestEvent';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '2',
          'Must decrease statistics for location when event is unpublished');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '2',
          'Must decrease statistics for city when event is unpublished');

-- Test case: must decrease statistics when event is cancelled
UPDATE events.Event
SET event_status = false
WHERE name = 'TestEvent3';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '1',
          'Must decrease statistics for location when event is cancelled');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '1',
          'Must decrease statistics for city when event is cancelled');

-- Test case: must update statistics when event location is updated
UPDATE events.Event
SET location_id = (SELECT id FROM events.Location WHERE name = 'TestLocation3')
WHERE name = 'TestEvent5';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '0',
          'Must decrease statistics for location when event location is moved');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '0',
          'Must decrease statistics for city when event location is moved');

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation3' LIMIT 1)),
          '1',
          'Must increase statistics for location when event location is moved');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity2' LIMIT 1)),
          '1',
          'Must decrease statistics for city when event location is moved');

-- Test case: must keep statistics when event is not moved
UPDATE events.Event
SET description = 'NewDescription'
WHERE name = 'TestEvent5';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation3' LIMIT 1)),
          '1',
          'Must keep statistics for location when event location is not moved');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity2' LIMIT 1)),
          '1',
          'Must keep statistics for city when event location is not moved');

-- Test case: must keep statistics when cancelled event is deleted
DELETE
FROM events.Event
WHERE name = 'TestEvent3';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation3' LIMIT 1)),
          '1',
          'Must keep statistics for location when cancelled event is deleted');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity2' LIMIT 1)),
          '1',
          'Must keep statistics for city when cancelled event is deleted');

-- Test case: must keep statistics when unpublished event is deleted
DELETE
FROM events.Event
WHERE name = 'TestEvent';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation3' LIMIT 1)),
          '1',
          'Must keep statistics for location when unpublished event is deleted');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity2' LIMIT 1)),
          '1',
          'Must keep statistics for city when unpublished event is deleted');

-- Test case: must decrease statistics when published event is deleted
DELETE
FROM events.event
WHERE name = 'TestEvent5';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation3' LIMIT 1)),
          '0',
          'Must decrease statistics for location when event is deleted');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity2' LIMIT 1)),
          '0',
          'Must decrease statistics for city when event is deleted');

-- Test case: must increase non-admin users when user is created
SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must create non-admin users statistics correctly');

-- Test case: must keep non-admin users count when admin user is created
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test4', 'test4', 'test4@test.com', 'password4', 'admin');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must keep non-admin users statistics after admin user insert');

-- Test case: must keep non-admin users count when admin user is updated into non-admin
UPDATE events.user
SET roles = 'user'
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '4',
          'Must keep non-admin users statistics after admin user is changed to non-admin');

-- Test case: must decrease non-admin users count when non-admin user is updated into admin
UPDATE events.user
SET roles = 'user,admin'
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must decrease non-admin users statistics after non-admin user is changed to admin');

-- Test case: must keep statistics on admin user delete
DELETE FROM events.user
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must keep non-admin users statistics after admin user is deleted');

-- Test case: must delete statistics on non-admin user delete
DELETE FROM events.user
WHERE email = 'test3@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '2',
          'Must decrease non-admin users statistics after non-admin user is deleted');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK
