\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(11);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_organizer_contact';
SELECT is(events.update_organizer_contact(
                  1::integer,
                  'TestContact',
                  'updated@contact.com',
                  ''
          ),
          'ERROR: Procedure update_organizer_contact is not registered in the procedures table',
          'Procedure update_organizer_contact missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_organizer_contact is not registered in the procedures table',
          'Create log entry for missing update_organizer_contact procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_organizer_contact', '');

-- Test case: organizer contact update with non-existing organizer ID
SELECT is(events.update_organizer_contact(
                  -1::integer,
                  'TestContact',
                  'updated@contact.com',
                  '666666666'
          ),
          'ERROR: Organizer contact does not exist',
          'update_organizer_contact must return error for non-existing organizer id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer contact does not exist',
          'Create log entry for non-existing organizer id'
       );

-- Test case: organizer contact update with non-existing name
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

SELECT is(events.update_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'NonExistingContact',
                  'updated@contact.com',
                  '666666666'
          ),
          'ERROR: Organizer contact does not exist',
          'update_organizer_contact must return error for non-existing contact name'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer contact does not exist',
          'Create log entry for non-existing contact name'
       );

-- Test case: organizer contact update with existing email
INSERT INTO events.organizer_contact (organizer_id, name, email, telephone)
VALUES ((SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        'ExistingContact',
        'existing@contact.com',
        '666666666'),
       ((SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        'TestContact',
        'test@contact.com',
        '666666666');

SELECT is(events.update_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact',
                  'existing@contact.com',
                  '777777777'
          ),
          'ERROR: Email "existing@contact.com" already assigned to another user',
          'update_organizer_contact must return error for existing email'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Email "existing@contact.com" already assigned to another user',
          'Create log entry for existing email'
       );

-- Test case: successful organizer contact update
SELECT is(events.update_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact',
                  'updated@contact.com',
                  '777777777'
          ),
          'OK',
          'update_organizer_contact must return OK for an existing organizer contact'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_organizer_contact'
       );

-- Check if the organizer contact was properly updated
SELECT is((SELECT email FROM events.organizer_contact WHERE name = 'TestContact'),
          'updated@contact.com',
          'Organizer contact must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;