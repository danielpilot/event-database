\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

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
        false,
        true,
        true,
        true,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation')),
       ('TestEvent3',
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

-- Test case: event not published with sales on insert
SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent'),
          'false',
          'Insert: sales must be deactivated on publish false');

-- Test case: event cancelled with sales on insert
SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent2'),
          'false',
          'Insert: sales must be deactivated on status false');

-- Test case: sales active when conditions are met on insert
SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent3'),
          'true',
          'Insert: sales must be activated');

-- Test case: sales must be active on update
UPDATE events.event
SET event_published = true,
    event_has_sales = true
WHERE name = 'TestEvent';

SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent'),
          'true',
          'Update: sales must be activated');

-- Test case: sales must be deactivated on update published false
UPDATE events.event
SET event_published = false
WHERE name = 'TestEvent';

SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent'),
          'false',
          'Update: sales must be deactivated on published false');

-- Test case: sales must be deactivated on update status false
UPDATE events.event
SET event_published = true,
    event_has_sales = true,
    event_status    = false
WHERE name = 'TestEvent';

SELECT is((SELECT event_has_sales
           FROM events.event
           WHERE name = 'TestEvent'),
          'false',
          'Update: sales must be activated on status false');

-- Test case: event status update must create cancelled event change
SELECT is((SELECT type FROM events.event_change ORDER BY id DESC LIMIT 1),
          'Cancelled',
          'Update: event has been cancelled'
       );

-- Test case: event date delayed must create delayed event change
UPDATE events.event
SET event_status = true,
    start_date   = NOW() + INTERVAL '1 day'
WHERE name = 'TestEvent';

SELECT is((SELECT type FROM events.event_change ORDER BY id DESC LIMIT 1),
          'Delayed',
          'Update: event has been delayed'
       );

-- Test case: event date advanced must create delayed event change
UPDATE events.event
SET event_status = true,
    start_date   = NOW() - INTERVAL '1 day'
WHERE name = 'TestEvent';

SELECT is((SELECT type FROM events.event_change ORDER BY id DESC LIMIT 1),
          'Other',
          'Update: event has been advanced'
       );

-- Test case: event location change must create location event change
UPDATE events.event
SET location_id = (SELECT id FROM events.Location WHERE name = 'TestLocation2')
WHERE name = 'TestEvent';

SELECT is((SELECT type FROM events.event_change ORDER BY id DESC LIMIT 1),
          'Location Change',
          'Update: event location has been changed'
       );

-- Test case: event price change must create price event change
UPDATE events.event
SET price = 2000.0
WHERE name = 'TestEvent';

SELECT is((SELECT type FROM events.event_change ORDER BY id DESC LIMIT 1),
          'Price Change',
          'Update: event price has been changed'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;