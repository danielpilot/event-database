\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(12);

-- Insert test data
INSERT INTO events.country (name)
VALUES ('TestCountry');
INSERT INTO events.region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.country WHERE name = 'TestCountry'));
INSERT INTO events.province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.region WHERE name = 'TestRegion' LIMIT 1));
INSERT INTO events.city (name, province_id)
SELECT 'TestCity ' || generate_series(1, 20),
       (SELECT id FROM events.province WHERE name = 'TestProvince' LIMIT 1);

INSERT INTO events.location (name, address, city_id, latitude, longitude)
SELECT 'TestLocation ' || s.i,
       'TestAddress ' || s.i,
       c.id::integer,
       0.0,
       0.0
FROM generate_series(1, 20) AS s(i)
         JOIN events.city AS c ON c.name = 'TestCity ' || s.i;

INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@test.com', 'Company');

INSERT INTO events."user" (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user');

INSERT INTO event (name,
                   start_date,
                   end_date,
                   schedule,
                   description,
                   price,
                   image,
                   event_status,
                   event_published,
                   event_has_sales,
                   comments,
                   organizer_id,
                   location_id)
SELECT 'Event ' || s.i,
       current_date,
       current_date,
       'Schedule',
       'Description ',
       1.0,
       '',
       true,
       true,
       true,
       true,
       (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer'),
       l.id::integer
FROM generate_series(1, 20) AS s(i)
         JOIN events.location AS l ON l.name = 'TestLocation ' || s.i;
;

INSERT INTO events.event_with_sales (event_id, capacity, sales, maximum_per_sale)
SELECT e.id,
       100,
       s.i,
       10
FROM generate_series(1, 20) AS s(i)
JOIN event AS e ON e.name = 'Event ' || s.i;

INSERT INTO statistics.event_statistics (event_id, ratings_count, average_rating, total_rating, favorites, occupation)
SELECT e.id,
       0,
       0.0,
       0.0,
       0,
       0
FROM generate_series(1, 20) AS s(i)
JOIN event AS e ON e.name = 'Event ' || s.i;

INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer
         FROM event
         WHERE name = 'Event 3'
         LIMIT 1),
        (SELECT id::integer FROM events."user" WHERE email = 'test@test.com'),
        5::integer,
        'This event is great',
        true);

INSERT INTO events.event_favorite (event_id, user_id)
VALUES ((SELECT id FROM event WHERE name = 'Event 3' LIMIT 1),
        (SELECT id FROM events."user" WHERE email = 'test@test.com'));

SELECT statistics.update_top_commented_events();
SELECT statistics.update_top_valued_events();
SELECT statistics.update_top_sold_events();
SELECT statistics.update_top_locations_with_events();
SELECT statistics.update_top_cities_with_events();
SELECT statistics.update_top_favorite_events();

-- Test case: top commented events updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_commented_events),
          '10',
          'Top commented events updated');

SELECT is((SELECT name
           FROM statistics.top_commented_events
           LIMIT 1),
          'Event 3',
          'Top commented events updated in correct order');

-- Test case: top valued events updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_valued_events),
          '10',
          'Top valued events updated');

SELECT is((SELECT name
           FROM statistics.top_valued_events
           LIMIT 1),
          'Event 3',
          'Top valued events updated in correct order');

-- Test case: top sold events updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_sold_events),
          '10',
          'Top sold events updated');

SELECT is((SELECT name
           FROM statistics.top_sold_events
           LIMIT 1),
          'Event 20',
          'Top sold events updated in correct order');

-- Test case: top event locations updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_event_locations),
          '20',
          'Top event locations updated');

SELECT is((SELECT name
           FROM statistics.top_event_locations
           LIMIT 1),
          'TestLocation 1',
          'Top event locations updated in correct order');

-- Test case: top event cities updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_event_cities),
          '10',
          'Top event cities updated');

SELECT is((SELECT name
           FROM statistics.top_event_cities
           LIMIT 1),
          'TestCity 1',
          'Top event cities updated in correct order');

-- Test case: top favorite events updated
SELECT is((SELECT COUNT(*)::text
           FROM statistics.top_favorite_events),
          '20',
          'Top favorite events updated');

SELECT is((SELECT name
           FROM statistics.top_favorite_events
           LIMIT 1),
          'Event 3',
          'Top favorite events updated in correct order');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK
