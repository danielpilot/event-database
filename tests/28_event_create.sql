\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(13);

-- Preload data
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

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_event';
SELECT is(events.create_event(
                  'TestEvent',
                  NOW()::timestamp,
                  NOW()::timestamp,
                  '',
                  '',
                  0.0,
                  '',
                  true,
                  true,
                  false,
                  (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer' LIMIT 1),
                  (SELECT id::integer FROM events.Location WHERE name = 'TestLocation' LIMIT 1),
                  ARRAY []::integer[],
                  NULL
          ),
          'ERROR: Procedure create_event is not registered in the procedures table',
          'Procedure create_event missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_event is not registered in the procedures table',
          'Create log entry for missing create_event procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_event', '');

-- Test case: successful event creation with non-existent categories
SELECT is(events.create_event(
                  'TestEventWithInvalidCategories',
                  NOW()::timestamp,
                  NOW()::timestamp,
                  '',
                  '',
                  0.0,
                  '',
                  true,
                  true,
                  false,
                  (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer' LIMIT 1),
                  (SELECT id::integer FROM events.Location WHERE name = 'TestLocation' LIMIT 1),
                  ARRAY [-1],
                  NULL
          ),
          'ERROR: Some categories do not exist',
          'create_event must return error for non-existent categories'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Some categories do not exist',
          'Create log entry for non-existent categories'
       );

-- Test case: successful event creation without sales
SELECT is(events.create_event(
                  'TestEvent',
                  NOW()::timestamp,
                  NOW()::timestamp,
                  '',
                  '',
                  0.0,
                  '',
                  true,
                  true,
                  false,
                  (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer' LIMIT 1),
                  (SELECT id::integer FROM events.Location WHERE name = 'TestLocation' LIMIT 1),
                  ARRAY []::integer[],
                  NULL
          ),
          'OK',
          'create_event must return OK for a valid event creation without sales'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event creation without sales'
       );

SELECT is((SELECT COUNT(*)::text FROM events.Event WHERE name = 'TestEvent'),
          '1',
          'Event without sales must be inserted into the table'
       );

-- Test case: successful event creation with existing categories
INSERT INTO events.Category (name)
VALUES ('TestCategory');
SELECT is(events.create_event(
                  'TestEventWithCategories',
                  NOW()::timestamp,
                  NOW()::timestamp,
                  '',
                  '',
                  0.0,
                  '',
                  true,
                  true,
                  false,
                  (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer' LIMIT 1),
                  (SELECT id::integer FROM events.Location WHERE name = 'TestLocation' LIMIT 1),
                  ARRAY [(SELECT id::integer FROM events.Category WHERE name = 'TestCategory')],
                  NULL
          ),
          'OK',
          'create_event must return OK for a valid event creation with existing categories'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event creation with categories'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.event_has_category
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEventWithCategories' LIMIT 1)
             AND category_id = (SELECT id FROM events.Category WHERE name = 'TestCategory' LIMIT 1)),
          '1',
          'Event and category must be related'
       );

-- Test case: successful event creation with sales
SELECT is(events.create_event(
                  'TestEventWithSales',
                  NOW()::timestamp,
                  NOW()::timestamp,
                  '',
                  '',
                  0.0,
                  '',
                  true,
                  true,
                  true,
                  (SELECT id::integer FROM events.organizer WHERE name = 'TestOrganizer' LIMIT 1),
                  (SELECT id::integer FROM events.Location WHERE name = 'TestLocation' LIMIT 1),
                  ARRAY []::integer[],
                  ROW (100, 10)::events.event_sales_data
          ),
          'OK',
          'create_event must return OK for a valid event creation with sales'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Event_With_Sales
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEventWithSales')),
          '1',
          'Event with sales must be created in the Event_With_Sales table'
       );


SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event creation with sales'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
