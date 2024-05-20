\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_organizer';
SELECT is(events.create_organizer('TestOrganizer', 'test@organizer.com', 'Company'),
          'ERROR: Procedure create_organizer is not registered in the procedures table',
          'Procedure create_organizer missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_organizer is not registered in the procedures table',
          'Create log entry for missing create_organizer procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_organizer', '');

-- Test case: organizer creation with existing email
INSERT INTO events.organizer (name, email, type)
VALUES ('ExistingOrganizer', 'existing@organizer.com', 'Company');

SELECT is(events.create_organizer('TestOrganizer', 'existing@organizer.com', 'Company'),
          'ERROR: Email "existing@organizer.com" already exists',
          'create_organizer must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Email "existing@organizer.com" already exists',
          'Create log entry for existing email'
       );

-- Test case: organizer creation with invalid type
SELECT is(events.create_organizer('TestOrganizer', 'test@organizer.com', 'InvalidType'),
          'ERROR: Invalid organizer type "InvalidType"',
          'create_organizer must return error for invalid organizer type'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Invalid organizer type "InvalidType"',
          'Create log entry for invalid organizer type'
       );

-- Test case: successful organizer creation
SELECT is(events.create_organizer('TestOrganizer', 'test@organizer.com', 'Company'),
          'OK',
          'create_organizer must return OK for a valid organizer'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_organizer'
       );

-- Check if the organizer was properly created
SELECT is((SELECT name FROM events.organizer WHERE name = 'TestOrganizer'),
          'TestOrganizer',
          'Organizer must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;