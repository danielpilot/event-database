\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_user';
SELECT is(events.delete_user(1::integer),
          'ERROR: Procedure delete_user is not registered in the procedures table',
          'Procedure delete_user missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_user is not registered in the procedures table',
          'Create log entry for missing delete_user procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_user', '');

-- Test case: user deletion with non-existing ID
SELECT is(events.delete_user(-1::integer),
          'ERROR: User "-1" does not exist',
          'delete_user must return error for non-existing user id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existing user id'
       );

-- Test case: successful user deletion
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user');

SELECT is(events.delete_user((SELECT id FROM events.User WHERE email = 'test@test.com')),
          'OK',
          'delete_user must return OK for a valid user deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_user'
       );

-- Check if the user was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.User WHERE email = 'test@test.com'),
          '0',
          'User must be deleted from the table'
       );

-- Test case: user delete with related transactions
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


WITH ews AS (
    INSERT INTO events.event_with_sales (event_id, capacity, maximum_per_sale)
        VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'), 10000, 100) RETURNING id)

INSERT
INTO events.transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id FROM ews),
        (SELECT id FROM events.User WHERE email = 'test@test.com'),
        0.0,
        1,
        'TEST1');

SELECT is(events.delete_user((SELECT id FROM events.User WHERE email = 'test@test.com')),
          'ERROR: User has related transactions',
          'delete_user must return error for user with related transactions'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User has related transactions',
          'Create log entry for user with related transactions'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
