\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(15);

-- Populate database
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user'),
       ('test2', 'test2', 'test2@test.com', 'password', 'user');
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
        (SELECT id FROM events.Location WHERE name = 'TestLocation')),
       ('TestEvent2',
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

INSERT INTO events.Event_With_Sales (event_id, capacity, maximum_per_sale)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1), 100, 10);

INSERT INTO events.Event_With_Sales (event_id, capacity, maximum_per_sale)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1), 100, 10);

-- Test case: checking if the transaction_create procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'create_transaction';
SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  1.0,
                  1::smallint,
                  'TEST1'
          ),
          'ERROR: Procedure create_transaction is not registered in the procedures table',
          'Procedure transaction_create missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_transaction is not registered in the procedures table',
          'Create log entry for missing create_transaction procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_transaction', '');

-- Test case: creating a transaction for an event with sales not opened
UPDATE events.Event
SET event_has_sales = false
WHERE name = 'TestEvent';

SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                  12.0,
                  2::smallint,
                  'TEST1'
          ),
          'ERROR: Event does not have sales enabled',
          'transaction_create must return error for event with sales not opened'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event does not have sales enabled',
          'Create log entry for event with sales not opened'
       );

UPDATE events.Event
SET event_has_sales = true
WHERE name = 'TestEvent';

-- Test case: creating a transaction with quantity exceeding the maximum per sale limit
SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                  12.0,
                  11::smallint,
                  'TEST1'
          ),
          'ERROR: Quantity "11" exceeds the maximum per sale limit',
          'create_transaction must return error for quantity exceeding the maximum per sale limit'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Quantity "11" exceeds the maximum per sale limit',
          'Create log entry for quantity exceeding the maximum per sale limit'
       );

-- Test case: creating a transaction for a non-existent user
SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  -1::integer,
                  12.0,
                  2::smallint,
                  'TEST1'
          ),
          'ERROR: User "-1" does not exist',
          'create_transaction must return error for non-existent user'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existent user'
       );

-- Test case: creating a transaction with a reference that already exists
INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id::integer
         FROM events.event_with_sales
         WHERE event_id = (SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1)
         LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test2@test.com'),
        12.0,
        2::smallint,
        'EXI1');

SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                  12.0,
                  2::smallint,
                  'EXI1'
          ),
          'ERROR: Transaction with reference "EXI1" already exists',
          'create_transaction must return error for reference that already exists'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Transaction with reference "EXI1" already exists',
          'Create log entry for reference that already exists'
       );

-- Test case: create a transaction for event when user already has one
SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent2' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test2@test.com'),
                  12.0,
                  2::smallint,
                  'REF2'
          ),
          'ERROR: Transaction already exists',
          'create_transaction must return error for transaction that already exists'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Transaction already exists',
          'Create log entry for transaction that already exists'
       );

-- Test case: successful transaction creation
SELECT is(events.create_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                  12.0,
                  2::smallint,
                  'TEST1'
          ),
          'OK',
          'transaction_create must return OK for a valid transaction creation'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid transaction creation'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Transaction
           WHERE event_id = (SELECT id::integer
                             FROM events.event_with_sales
                             WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                             LIMIT 1)),
          '1',
          'Transaction must be created in the Transaction table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;