\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

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
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1), 100, 10),
       ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent2' LIMIT 1), 100, 10);

INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id::integer
         FROM events.event_with_sales
         WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
         LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        1.0,
        1::integer,
        'REF1');

-- Test case: checking if the delete_transaction procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'delete_transaction';
SELECT is(events.delete_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1)
          ),
          'ERROR: Procedure delete_transaction is not registered in the procedures table',
          'Procedure delete_transaction missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_transaction is not registered in the procedures table',
          'Create log entry for missing delete_transaction procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_transaction', '');

-- Test case: deleting a transaction for event when user does not have one
SELECT is(events.delete_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent2' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test2@test.com')
          ),
          'ERROR: Transaction does not exist',
          'delete_transaction must return error for transaction that does not exist'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Transaction does not exist',
          'Create log entry for transaction that does not exist'
       );

-- Test case: successful transaction deletion
SELECT is(events.delete_transaction(
                  (SELECT id::integer
                   FROM events.event_with_sales
                   WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                   LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com')
          ),
          'OK',
          'delete_transaction must return OK for a valid transaction deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid transaction deletion'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Transaction
           WHERE event_id = (SELECT id::integer
                             FROM events.event_with_sales
                             WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                             LIMIT 1)),
          '0',
          'Transaction must be deleted from the Transaction table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
