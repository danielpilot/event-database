\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_organizer_contact';
SELECT is(events.delete_organizer_contact(1::integer, 'TestContact'),
          'ERROR: Procedure delete_organizer_contact is not registered in the procedures table',
          'Procedure delete_organizer_contact missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_organizer_contact is not registered in the procedures table',
          'Create log entry for missing delete_organizer_contact procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_organizer_contact', '');

-- Test case: organizer contact deletion with non-existing organizer ID
SELECT is(events.delete_organizer_contact(-1::integer, 'TestContact'),
          'ERROR: Organizer contact does not exist',
          'delete_organizer_contact must return error for non-existing organizer id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer contact does not exist',
          'Create log entry for non-existing organizer id'
       );

-- Test case: organizer contact deletion with non-existing name
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

SELECT is(events.delete_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'NonExistingContact'
          ),
          'ERROR: Organizer contact does not exist',
          'delete_organizer_contact must return error for non-existing contact name'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Organizer contact does not exist',
          'Create log entry for non-existing contact name'
       );

-- Test case: successful organizer contact deletion
INSERT INTO events.organizer_contact (organizer_id, name, email, telephone)
VALUES ((SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        'TestContact',
        'test@contact.com',
        '666666666');

SELECT is(events.delete_organizer_contact(
                  (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
                  'TestContact'
          ),
          'OK',
          'delete_organizer_contact must return OK for an existing organizer contact'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_organizer_contact'
       );

-- Check if the organizer contact was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.organizer_contact WHERE name = 'TestContact'),
          '0',
          'Organizer contact must be deleted from the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;