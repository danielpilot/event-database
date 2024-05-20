\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_organizer';
SELECT is(events.update_organizer(1, 'UpdatedOrganizer', 'updated@organizer.com', 'Company'),
          'ERROR: Procedure update_organizer is not registered in the procedures table',
          'Procedure update_organizer missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_organizer is not registered in the procedures table',
          'Create log entry for missing update_organizer procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_organizer', '');

-- Test case: organizer update with non-existing ID
SELECT is(events.update_organizer(
                  -1::integer,
                  'UpdatedOrganizer',
                  'updated@organizer.com',
                  'Company'
          ),
          'ERROR: Organizer "-1" does not exist',
          'update_organizer must return error for non-existing organizer id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer "-1" does not exist',
          'Create log entry for non-existing organizer id'
       );

-- Test case: organizer update with existing email
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

INSERT INTO events.organizer (name, email, type)
VALUES ('ExistingOrganizer', 'existing@organizer.com', 'Company');

SELECT is(events.update_organizer(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'UpdatedOrganizer',
                  'existing@organizer.com',
                  'Company'
          ),
          'ERROR: Email "existing@organizer.com" already assigned to another user',
          'update_organizer must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Email "existing@organizer.com" already assigned to another user',
          'Create log entry for existing email'
       );

-- Test case: organizer update with invalid type
SELECT is(events.update_organizer(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'UpdatedOrganizer',
                  'updated@organizer.com',
                  'InvalidType'
          ),
          'ERROR: Invalid organizer type "InvalidType"',
          'update_organizer must return error for invalid organizer type'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Invalid organizer type "InvalidType"',
          'Create log entry for invalid organizer type'
       );

-- Test case: successful organizer update

SELECT is(events.update_organizer(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'UpdatedOrganizer',
                  'updated@organizer.com',
                  'Company'
          ),
          'OK',
          'update_organizer must return OK for an existing organizer'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_organizer'
       );

-- Check if the organizer was properly updated
SELECT is((SELECT name FROM events.organizer WHERE name = 'UpdatedOrganizer'),
          'UpdatedOrganizer',
          'Organizer must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
