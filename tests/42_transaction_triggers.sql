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
        false,
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

-- Test case: check if event sales are closed on insert
PREPARE insert_event_closed AS INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
                               VALUES ((SELECT id::integer
                                        FROM events.event_with_sales
                                        WHERE event_id =
                                              (SELECT id::integer FROM events.event WHERE name = 'TestEvent' LIMIT 1)
                                        LIMIT 1),
                                       (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                                       1.0,
                                       1::integer,
                                       'TEST1');

SELECT throws_ok('insert_event_closed',
                 'Event sales are closed',
                 'Insert: Event sales are closed');

-- Test case: check if not enough tickets are available on insert
PREPARE insert_not_enough_tickets AS INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
                                     VALUES ((SELECT id::integer
                                              FROM events.event_with_sales
                                              WHERE event_id = (SELECT id::integer
                                                                FROM events.event
                                                                WHERE name = 'TestEvent2'
                                                                LIMIT 1)
                                              LIMIT 1),
                                             (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                                             1.0,
                                             1000::integer,
                                             'TEST1');

SELECT throws_ok('insert_not_enough_tickets',
                 'Not enough tickets are available',
                 'Insert: Not enough tickets available');

-- Test case: check if not enough tickets exception is thrown
UPDATE event_with_sales
SET capacity = 10,
    sales    = 8
WHERE event_id = (SELECT id::integer FROM events.event WHERE name = 'TestEvent2' LIMIT 1);

PREPARE insert_not_enough_tickets_with_sales_count AS INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
                                                      VALUES ((SELECT id::integer
                                                               FROM events.event_with_sales
                                                               WHERE event_id = (SELECT id::integer
                                                                                 FROM events.event
                                                                                 WHERE name = 'TestEvent2'
                                                                                 LIMIT 1)
                                                               LIMIT 1),
                                                              (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
                                                              1.0,
                                                              3::integer,
                                                              'TEST1');

SELECT throws_ok('insert_not_enough_tickets_with_sales_count',
                 'Not enough tickets are available',
                 'Insert: Not enough tickets available with current sales count');

-- Test case: insert transaction when conditions are met
INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
VALUES ((SELECT id::integer
         FROM events.event_with_sales
         WHERE event_id = (SELECT id::integer
                           FROM events.event
                           WHERE name = 'TestEvent2'
                           LIMIT 1)
         LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com'),
        1.0,
        2::integer,
        'TEST1');

-- Test case: check if sales are updated on insert
SELECT is((SELECT sales
           FROM events.event_with_sales
           WHERE event_id = (SELECT id::integer
                             FROM events.event
                             WHERE name = 'TestEvent2'
                             LIMIT 1)),
          '10',
          'Insert: Sales must be updated');

-- Test case: check if transaction is created
SELECT is((SELECT COUNT(*)::text
           FROM events.Transaction
           WHERE reference = 'TEST1'),
          '1',
          'Insert: Transaction must be created');

-- Test case: check if not enough tickets are available on update
PREPARE update_not_enough_tickets AS UPDATE events.Transaction
                                     SET quantity = 1000
                                     WHERE reference = 'TEST1';

SELECT throws_ok('update_not_enough_tickets',
                 'Not enough tickets are available',
                 'Update: Not enough tickets available');

-- Test case: check if sales are closed on update
UPDATE events.event
SET event_has_sales = false
WHERE name = 'TestEvent2';

PREPARE update_event_closed AS UPDATE events.Transaction
                               SET quantity = 1
                               WHERE reference = 'TEST1';

SELECT throws_ok('update_event_closed',
                 'Event sales are closed',
                 'Update: Event sales are closed');

-- Test case: check if update is done on update
UPDATE events.event
SET event_has_sales = true
WHERE name = 'TestEvent2';

UPDATE events.Transaction
SET quantity = 1
WHERE reference = 'TEST1';

SELECT is((SELECT COUNT(*)::text
           FROM events.Transaction
           WHERE reference = 'TEST1' AND quantity = 1),
          '1',
          'Transaction must be updated');

-- Test case: check sales are updated with decreased number on update
SELECT is((SELECT sales
           FROM events.event_with_sales
           WHERE event_id = (SELECT id::integer
                             FROM events.event
                             WHERE name = 'TestEvent2'
                             LIMIT 1)),
          '9',
          'Update: Sales must be updated - Decrease sales');

-- Test case: check sales are updated with increased number on update
UPDATE events.Transaction
SET quantity = 2
WHERE reference = 'TEST1';

SELECT is((SELECT sales
           FROM events.event_with_sales
           WHERE event_id = (SELECT id::integer
                             FROM events.event
                             WHERE name = 'TestEvent2'
                             LIMIT 1)),
          '10',
          'Update: Sales must be updated - Increase sales');

-- Test case: check sales are updated on delete
DELETE FROM events.Transaction
WHERE reference = 'TEST1';

SELECT is((SELECT sales
           FROM events.event_with_sales
           WHERE event_id = (SELECT id::integer
                             FROM events.event
                             WHERE name = 'TestEvent2'
                             LIMIT 1)),
          '8',
          'Delete: Sales must be updated');

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
