\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_organizer_contact';
SELECT is(events.create_organizer_contact(
                  1::integer,
                  'TestContact',
                  'test@contact.com',
                  ''
          ),
          'ERROR: Procedure create_organizer_contact is not registered in the procedures table',
          'Procedure create_organizer_contact missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_organizer_contact is not registered in the procedures table',
          'Create log entry for missing create_organizer_contact procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_organizer_contact', '');

-- Test case: organizer contact creation with non-existing organizer ID
SELECT is(events.create_organizer_contact(
                  -1::integer,
                  'TestContact',
                  'test@contact.com',
                  ''
          ),
          'ERROR: Organizer "-1" does not exist',
          'create_organizer_contact must return error for non-existing organizer id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer "-1" does not exist',
          'Create log entry for non-existing organizer id'
       );

-- Test case: organizer contact creation with duplicates
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

INSERT INTO events.organizer_contact (organizer_id, name, email, telephone)
VALUES ((SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        'TestContact',
        'test@contact.com',
        '666666666');

SELECT is(events.create_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact',
                  'existing@contact.com',
                  '666666666'
          ),
          'ERROR: Contact already exists',
          'create_organizer_contact must return error for duplicate user'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Contact already exists',
          'Create log entry for duplicate user'
       );

-- Test case: organizer contact creation with existing email
SELECT is(events.create_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact2',
                  'test@contact.com',
                  '666666666'
          ),
          'ERROR: Email "test@contact.com" already exists',
          'create_organizer_contact must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Email "test@contact.com" already exists',
          'Create log entry for existing email'
       );

-- Test case: successful organizer contact creation
SELECT is(events.create_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact3',
                  'test3@contact.com',
                  '666666666'
          ),
          'OK',
          'create_organizer_contact must return OK for a valid organizer contact'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_organizer_contact'
       );

-- Check if the organizer contact was properly created
SELECT is((SELECT name FROM events.organizer_contact WHERE name = 'TestContact3'),
          'TestContact3',
          'Organizer contact must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
