\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_user';
SELECT is(events.update_user(
                  1::integer,
                  'test',
                  'test',
                  'test@test.com',
                  'password',
                  'user'
          ),
          'ERROR: Procedure update_user is not registered in the procedures table',
          'Procedure update_user missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_user is not registered in the procedures table',
          'Create log entry for missing update_user procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_user', '');

-- Test case: user update with non-existing ID
SELECT is(events.update_user(
                  -1::integer,
                  'test',
                  'test',
                  'test@test.com',
                  'password',
                  'user'
          ),
          'ERROR: User "-1" does not exist',
          'update_user must return error for non-existing user id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existing user id'
       );

-- Test case: user update with existing email
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('exists', 'exists', 'exists@test.com', 'password', 'user');

INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('test', 'test', 'test@test.com', 'password', 'user');

SELECT is(events.update_user(
                  (SELECT id FROM events.User WHERE email = 'test@test.com'),
                  'test',
                  'test',
                  'exists@test.com',
                  'password',
                  'user'
          ),
          'ERROR: User with email "exists@test.com" already exists',
          'update_user must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User with email "exists@test.com" already exists',
          'Create log entry for existing email'
       );

-- Test case: successful user update
SELECT is(events.update_user(
                  (SELECT id FROM events.User WHERE email = 'test@test.com'),
                  'updated',
                  'updated',
                  'updated@test.com',
                  'password',
                  'user'
          ),
          'OK',
          'update_user must return OK for a valid user update'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_user'
       );

-- Check if the user was properly updated
SELECT is((SELECT COUNT(*)::text FROM events.User WHERE email = 'updated@test.com'),
          '1',
          'User must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
