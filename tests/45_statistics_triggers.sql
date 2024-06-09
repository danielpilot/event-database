\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(155);

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
        5.0,
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
        7.0,
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '0',
          'Must keep total events counter when unpublished event was created');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '0',
          'Must keep total event sales counter when unpublished event was created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '0',
          'Must keep total payed events percentage when unpublished event was created');

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
        15.3,
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '0',
          'Must keep total events counter when cancelled event is created');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '0',
          'Must keep total event sales counter when cancelled event is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '0',
          'Must keep total payed events percentage when cancelled event is created');

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
        10.0,
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '1',
          'Must increase total events counter when event is created');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must increase total event sales counter when event is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '100',
          'Must update total payed events percentage when event is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must update total payed events price when event is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must update total average events price when event is created');

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
        false,
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '2',
          'Must increase total events counter when non-payed event is created');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must not increase total event sales counter when non-payed event is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '50',
          'Must update total payed events percentage when non-payed event is created');

-- Test case: must increase statistics when unpublished event gets published
UPDATE events.Event
SET event_published = true,
    event_has_sales = true
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '3',
          'Must increase total events counter when event is published');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '2',
          'Must increase total event sales counter when event with sales sales is published');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '66.67',
          'Must update total payed events percentage when event is published');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '15',
          'Must update total payed events price when event is published');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '7.5',
          'Must update total average events price when event is published');

-- Test case: must increase statistics when cancelled event gets programmed
UPDATE events.Event
SET event_status    = true,
    event_has_sales = true
WHERE name = 'TestEvent3';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '4',
          'Must increase statistics for location when event is programmed');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '4',
          'Must increase statistics for city when event is programmed');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '4',
          'Must increase total events counter when event is programmed');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '3',
          'Must update total event sales counter when event is programmed');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '75',
          'Must update total payed events percentage when event is programmed');

-- Test case: must decrease statistics when published event gets unpublished
UPDATE events.Event
SET event_published = false
WHERE name = 'TestEvent';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '3',
          'Must decrease statistics for location when event is unpublished');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '3',
          'Must decrease statistics for city when event is unpublished');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '3',
          'Must decrease total events counter when event is unpublished');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '2',
          'Must decrease event sales counter when is unpublished');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '66.67',
          'Must update total payed events percentage when event is unpublished');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '25.3',
          'Must update total payed events price when event is unpublished');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '12.5',
          'Must update total average events price when event is unpublished');

-- Test case: must update price statistics when price changes
UPDATE events.Event
SET price = 50.2
WHERE name = 'TestEvent3';

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '60.2',
          'Must update total payed events price when price changes');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '30',
          'Must update total average events price when price changes');

-- Test case: must update price when event has no sales anymore
UPDATE events.Event
SET event_has_sales = false
WHERE name = 'TestEvent3';

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must update total payed events price when event sales are disabled');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must update total average events price when event sales are disabled');

-- Test case: must update price when event updates to have sales
UPDATE events.Event
SET event_has_sales = true
WHERE name = 'TestEvent3';

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '60.2',
          'Must update total payed events price when event updates to have sales');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '30',
          'Must update total average events price when event updates to have sales');

-- Test case: must decrease statistics when event is cancelled
UPDATE events.Event
SET event_status = false
WHERE name = 'TestEvent3';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '2',
          'Must decrease statistics for location when event is cancelled');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '2',
          'Must decrease statistics for city when event is cancelled');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '2',
          'Must decrease total events counter when event is cancelled');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must decrease total event sales counter when event is cancelled');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '50',
          'Must update total payed events percentage when event is cancelled');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must update total payed events price when event is cancelled');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must update total average events price when is cancelled');

-- Test case: must update statistics when event location is updated
UPDATE events.Event
SET location_id = (SELECT id FROM events.Location WHERE name = 'TestLocation3')
WHERE name = 'TestEvent5';

SELECT is((SELECT events::text
           FROM statistics.location_statistics
           WHERE location_id = (SELECT id::integer FROM events.location WHERE name = 'TestLocation' LIMIT 1)),
          '1',
          'Must decrease statistics for location when event location is moved');

SELECT is((SELECT events::text
           FROM statistics.city_statistics
           WHERE city_id = (SELECT id::integer FROM events.city WHERE name = 'TestCity' LIMIT 1)),
          '1',
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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '2',
          'Must keep total events counter when cancelled event is deleted');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must keep total event sales counter when cancelled event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '50',
          'Must keep total payed events percentage when cancelled event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must keep total payed events price when cancelled event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must keep total average events price when cancelled event is deleted');

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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '2',
          'Must keep total events counter when unpublished event is deleted');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must keep total event sales counter when unpublished event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '50',
          'Must keep total payed events percentage when unpublished event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must keep total payed events price when unpublished event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must keep total average events price when unpublished event is deleted');

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

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '1',
          'Must decrease total events counter when event is deleted');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '1',
          'Must keep total event sales counter when event without sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '100',
          'Must update payed events percentage when event is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '10',
          'Must keep total payed events price when event without sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '10',
          'Must keep total average events price when event without sales is deleted');

-- Test case: must decrease statistic when published event with sales is deleted
DELETE
FROM events.event
WHERE name = 'TestEvent4';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_events'),
          '0',
          'Must decrease total events counter when event with sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_payed_events'),
          '0',
          'Must decrease total event sales counter when event with sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 3),
          '0',
          'Must update payed events percentage when event with sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 4),
          '0',
          'Must update total payed events price when event with sales is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 1),
          '0',
          'Must update total average events price when event with sales is deleted');

-- Test case: must increase non-admin users when user is created
SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must create non-admin users statistics correctly');

-- Test case: must update average transactions per user when transaction is created
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
INSERT INTO event_with_sales (event_id, capacity, maximum_per_sale)
VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'),
        4,
        10);

INSERT INTO events.transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id::integer
         FROM events.event_with_sales
         WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
         LIMIT 1),
        (SELECT id::integer FROM events.user WHERE email = 'test@test.com'),
        12.0,
        2,
        'ref');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.33',
          'Must update average transactions per user when transaction is created');

-- Test case: update occupation statistics when transaction is created
SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '50',
          'Must update event occupation when transaction is created');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '0',
          'Must update full event statistics when transaction is crated and event is not full');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '50',
          'Must update total number of occupation percentages when transaction is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '50',
          'Must update average percentage of occupation when transaction is created');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '0',
          'Must update percentage of full events when transaction is crated and event is not full');

-- Test case: update current month transactions when transaction is created
SELECT is((SELECT transactions::text
           FROM statistics.transaction_statistics
           WHERE month = EXTRACT(MONTH FROM CURRENT_DATE)
             AND year = EXTRACT(YEAR FROM CURRENT_DATE)),
          '1',
          'Must update current month transactions when first transaction is created');

-- Test case: update variation percentage when transaction is created
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 5),
          '100',
          'Must update current month transactions when first transaction is created');

-- Test case: must update average transactions per user when non admin user is created
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test4', 'test4', 'test4@test.com', 'password4', 'user');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.25',
          'Must update average transactions per user when non admin user is created');

-- Test case: must update current month transactions when new transaction is created
INSERT INTO events.transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id::integer
         FROM events.event_with_sales
         WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)
         LIMIT 1),
        (SELECT id::integer FROM events.user WHERE email = 'test4@test.com'),
        12.0,
        2,
        'ref2');

SELECT is((SELECT transactions::text
           FROM statistics.transaction_statistics
           WHERE month = EXTRACT(MONTH FROM CURRENT_DATE)
             AND year = EXTRACT(YEAR FROM CURRENT_DATE)),
          '2',
          'Must update current month transactions when transaction is created');

SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '100',
          'Must update event occupation when transaction is created');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '1',
          'Must keep full event statistics when transaction is crated and event is full');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '100',
          'Must update total number of occupation percentages when transaction is created and event is full');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '100',
          'Must update average percentage of occupation when transaction is created and event is full');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '100',
          'Must update percentage of full events when transaction is crated and event is full');

-- Test case: must update transaction statistics on date change
UPDATE events.transaction
SET date = NOW() - INTERVAL '1 month'
WHERE reference = 'ref2';

SELECT is((SELECT transactions::text
           FROM statistics.transaction_statistics
           WHERE month = EXTRACT(MONTH FROM CURRENT_DATE)
             AND year = EXTRACT(YEAR FROM CURRENT_DATE)),
          '1',
          'Must update current month transactions when transaction month is moved');

SELECT is((SELECT transactions::text
           FROM statistics.transaction_statistics
           WHERE month = EXTRACT(MONTH FROM NOW() - INTERVAL '1 month')
             AND year = EXTRACT(YEAR FROM NOW() - INTERVAL '1 month')),
          '1',
          'Must update new month transactions when transaction month is moved');


-- Test case: must update occupation statistics when transaction decreases its quantity
UPDATE events.transaction
SET quantity = 1
WHERE reference = 'ref2';

SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '75',
          'Must update event occupation when transaction quantity is decreased');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '0',
          'Must decrease event statistics when transaction quantity is decreased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '75',
          'Must update total number of occupation percentages when transaction quantity is decreased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '75',
          'Must update average percentage of occupation when transaction quantity is decreased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '0',
          'Must update percentage of full events when transaction quantity is decreased');

-- Test case: must update occupation statistics when transaction increases its quantity
UPDATE events.transaction
SET quantity = 2
WHERE reference = 'ref2';

SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '100',
          'Must update event occupation when transaction quantity is increased');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '1',
          'Must keep full event statistics when transaction quantity is increased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '100',
          'Must update total number of occupation percentages when transaction quantity is increased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '100',
          'Must update average percentage of occupation when transaction quantity is increased');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '100',
          'Must update percentage of full events when transaction quantity is increased');

-- Test case: must update occupation statistics when event with sales changes its quantity
UPDATE event_with_sales
SET capacity = 10
WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent');

SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '40',
          'Must update event occupation when event quantity is updated');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '0',
          'Must keep full event statistics when event quantity is updated');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '40',
          'Must update total number of occupation percentages when event quantity is updated');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '40',
          'Must update average percentage of occupation when event quantity is updated');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '0',
          'Must update percentage of full events when event quantity is updated');

-- Test case: update variation percentage on date change
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 5),
          '0',
          'Must update current month transactions when transaction month is moved');

DELETE
FROM events.transaction
WHERE reference = 'ref2';

DELETE
FROM events.User
WHERE email = 'test4@test.com';

-- Test case: must keep non-admin users count when admin user is created
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test4', 'test4', 'test4@test.com', 'password4', 'admin');

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must keep non-admin users statistics after admin user insert');

-- Test case: must keep average transactions per user when non admin user is created
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.33',
          'Must keep average transactions per user when non admin user is created');

-- Test case: must increase non-admin users count when admin user is updated into non-admin
UPDATE events.user
SET roles = 'user'
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '4',
          'Must increase non-admin users statistics after admin user is changed to non-admin');

-- Test case: must update average transactions per user when admin user is updated into non-admin
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.25',
          'Must update average transactions per user after admin user is changed to non-admin');

-- Test case: must decrease non-admin users count when non-admin user is updated into admin
UPDATE events.user
SET roles = 'user,admin'
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must decrease non-admin users statistics after non-admin user is changed to admin');

-- Test case: must update average transactions per user when non-admin user is updated into admin
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.33',
          'Must update average transactions per user after non-admin user is changed to admin');

-- Test case: must keep statistics on admin user delete
DELETE
FROM events.user
WHERE email = 'test4@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '3',
          'Must keep non-admin users statistics after admin user is deleted');

-- Test case: must keep average transactions per user when admin user is deleted
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.33',
          'Must keep average transactions per user after admin user is deleted');

-- Test case: must delete statistics on non-admin user delete
DELETE
FROM events.user
WHERE email = 'test3@test.com';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'non_admin_users'),
          '2',
          'Must decrease non-admin users statistics after non-admin user is deleted');

-- Test case: must update average transactions per user when non-admin user is deleted
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0.5',
          'Must update average transactions per user after non-admin user is deleted');

-- Test case: must increase total transactions when transaction is created
SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_transactions'),
          '1',
          'Must increase total transactions statistics when transaction is created');

-- Test case: must decrease total transactions when transaction is deleted
DELETE
FROM events.transaction
WHERE reference = 'ref';

SELECT is((SELECT value::text
           FROM statistics.system_counters
           WHERE name = 'total_transactions'),
          '0',
          'Must decrease total transactions statistics when transaction is deleted');

SELECT is((SELECT transactions::text
           FROM statistics.transaction_statistics
           WHERE month = EXTRACT(MONTH FROM CURRENT_DATE)
             AND year = EXTRACT(YEAR FROM CURRENT_DATE)),
          '0',
          'Must update current month transactions when transaction is deleted');

-- Test case: must update occupation statistics when transaction is deleted
SELECT is((SELECT occupation::text
           FROM statistics.event_statistics
           WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1)),
          '0',
          'Must update event occupation when transaction is deleted');

SELECT is((SELECT value::text
           FROM statistics.integer_indicators
           WHERE indicator = 1),
          '0',
          'Must keep full event statistics when transaction is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 6),
          '0',
          'Must update total number of occupation percentages when transaction is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 7),
          '0',
          'Must update average percentage of occupation when transaction is deleted');

SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 8),
          '0',
          'Must update percentage of full events when transaction is deleted');

-- Test case: must update average transactions per user when transaction is deleted
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 2),
          '0',
          'Must update average transactions per user when transaction is deleted');

-- Test case: update variation percentage on date change
SELECT is((SELECT value::text
           FROM statistics.percentage_indicators
           WHERE indicator = 5),
          '100',
          'Must update current month transactions when transaction month is deleted');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK
