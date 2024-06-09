\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(2);

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
        true,
        true,
        false,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));

-- Test case: event not published with sales on insert
PREPARE insert_rating_disabled AS INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
                                  VALUES ((SELECT id::integer
                                           FROM events.event
                                           WHERE name = 'TestEvent'
                                           LIMIT 1),
                                          (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                                          5::integer,
                                          'This event is great',
                                          TRUE);

SELECT throws_ok('insert_rating_disabled',
                 'Comments are not enabled for this event',
                 'Insert: Comments not enabled for the event');

-- Test case: event not published with sales on update
UPDATE events.event
SET comments = true
WHERE name = 'TestEvent';

INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer
         FROM events.event
         WHERE name = 'TestEvent'
         LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        5::integer,
        'This event is great',
        TRUE);

UPDATE events.event
SET comments = false
WHERE name = 'TestEvent';

PREPARE update_rating_disabled AS INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
                                  VALUES ((SELECT id::integer
                                           FROM events.event
                                           WHERE name = 'TestEvent'
                                           LIMIT 1),
                                          (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                                          1::integer,
                                          'This event is awful',
                                          FALSE);

SELECT throws_ok('update_rating_disabled',
                 'Comments are not enabled for this event',
                 'Update: Comments not enabled for the event');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;