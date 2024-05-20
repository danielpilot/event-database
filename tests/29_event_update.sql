\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(32);

-- Pre set data
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

-- Test case: updating an event that does not exist
SELECT is(events.update_event(
                  -1,
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
          'ERROR: Event "-1" does not exist',
          'update_event must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: updating an event with non-existent categories
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
                  ARRAY [-1],
                  NULL
          ),
          'ERROR: Some categories do not exist',
          'update_event must return error for non-existent categories'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Some categories do not exist',
          'Create log entry for non-existent categories'
       );

-- Test case: updating an event without sales
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  'TestEvent1',
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
          'update_event must return OK for a valid event update without sales'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event update without sales'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event update without sales'
       );

SELECT is((SELECT COUNT(*)::text FROM events.Event WHERE name = 'TestEvent1'),
          '1',
          'Event without sales must be updated in the table'
       );

-- Test case: updating an event with sales
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent1' LIMIT 1),
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
                  ROW (100, 10)::events.event_sales_data
          ),
          'OK',
          'update_event must return OK for a valid event update with sales'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event update with sales'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.event_with_sales
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '1',
          'Event without sales must be created in the table'
       );

SELECT is((SELECT event.event_has_sales FROM events.Event WHERE name = 'TestEvent'),
          'true',
          'Event sales must be active'
       );

-- Test case: updating an event to remove all categories
INSERT INTO events.Category (name, parent_category)
VALUES ('TestCategory', NULL);

INSERT INTO events.Event_has_Category (event_id, category_id)
VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id FROM events.Category WHERE name = 'TestCategory'));

SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
          'update_event must return OK for a valid event update removing all categories'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event update removing all categories'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Event_has_Category
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '0',
          'All categories must be removed from the event'
       );

-- Test case: add categories to an event
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
                  ARRAY [(SELECT id::integer FROM events.Category WHERE name = 'TestCategory')],
                  NULL
          ),
          'OK',
          'update_event must return OK for a valid event update adding a category'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid event update adding a category'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Event_has_Category
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '1',
          'Event must have added category'
       );

-- Test case: updating an event to remove sales data
INSERT INTO events.event_with_sales (event_id, capacity, maximum_per_sale)
VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'), 10000, 100);

SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
          'update_event must return OK for a valid event update removing sales data'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid update removing sales data'
       );

SELECT is((SELECT COUNT(*)
           FROM events.event_with_sales
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '0',
          'Event sales data must be removed from the table'
       );

SELECT is((SELECT event.event_has_sales FROM events.Event WHERE name = 'TestEvent'),
          'false',
          'Event sales must not be active'
       );

-- Test case: updating an event to add sales data when it previously had none
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
                  ROW (100, 10)::events.event_sales_data
          ),
          'OK',
          'update_event must return OK for a valid event update adding sales data'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid update adding sales data'
       );

SELECT is((SELECT COUNT(*)
           FROM events.event_with_sales
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')),
          '1',
          'Event sales data must be added from the table'
       );

SELECT is((SELECT event.event_has_sales FROM events.Event WHERE name = 'TestEvent'),
          'true',
          'Event sales must be active after adding sales data'
       );

-- Test case: updating an event to change its sales data when it previously had some
SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
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
                  ROW (200, 20)::events.event_sales_data
          ),
          'OK',
          'update_event must return OK for a valid event update changing sales data'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid update adding sales data'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.event_with_sales
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent') AND capacity = 200 AND maximum_per_sale = 20),
          '1',
          'Event without sales must be created in the table'
       );

-- Test case: attempting to update an event that has sales data and related transactions, to remove its sales data
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user');

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
VALUES ('TestEventWithSales',
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


WITH ews AS (
    INSERT INTO events.event_with_sales (event_id, capacity, maximum_per_sale)
        VALUES ((SELECT id FROM events.Event WHERE name = 'TestEventWithSales'), 10000, 100) RETURNING id)

INSERT
INTO events.transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id FROM ews),
        (SELECT id FROM events.User WHERE email = 'test@test.com'),
        0.0,
        1,
        'TEST1');

SELECT is(events.update_event(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEventWithSales' LIMIT 1),
                  'TestEventWithSales',
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
          'INFO: Unable to remove event with sales with related transactions',
          'update_event must return info message for an event update attempting to remove sales data with related transactions'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'INFO: Unable to remove event with sales with related transactions',
          'Create log entry for info not removing event with sales'
       );

SELECT is((SELECT event.event_has_sales::text FROM events.Event WHERE name = 'TestEventWithSales'),
          'false',
          'Event sales must not be active when disabling sales with transactions'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
