\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(7);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_user';
SELECT is(events.create_user('test', 'test', 'test@test.com', 'password', 'user'),
          'ERROR: Procedure create_user is not registered in the procedures table',
          'Procedure create_user missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_user is not registered in the procedures table',
          'Create log entry for missing create_user procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_user', '');

-- Test case: user creation with existing email
INSERT INTO events.User (name, surname, email, password, roles)
VALUES ('exists', 'exists', 'exists@test.com', 'password', 'user');

SELECT is(events.create_user('test', 'test', 'exists@test.com', 'password', 'user'),
          'ERROR: User with email "exists@test.com" already exists',
          'create_user must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User with email "exists@test.com" already exists',
          'Create log entry for existing email'
       );

-- Test case: successful user creation
SELECT is(events.create_user('test', 'test', 'test@test.com', 'password', 'user'),
          'OK',
          'create_user must return OK for a valid user creation'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_user'
       );

-- Check if the user was properly inserted
SELECT is((SELECT COUNT(*)::text FROM events.User WHERE email = 'test@test.com'),
          '1',
          'User must be inserted into the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;