\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_country';
SELECT is(events.delete_country(1::smallint),
          'ERROR: Procedure delete_country is not registered in the procedures table',
          'Procedure delete_country missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_country is not registered in the procedures table',
          'Create log entry for missing delete_country procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_country', '');

-- Test case: country ID missing
SELECT is(events.delete_country(-1::smallint),
          'ERROR: Country "-1" does not exist',
          'delete_country must return error for non-existing country id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country "-1" does not exist',
          'Create log entry for non-existing country id'
       );

-- Test case: successful country deletion
INSERT INTO events.Country (name)
VALUES ('TestCountry');

SELECT is(events.delete_country((SELECT id FROM events.Country WHERE name = 'TestCountry')),
          'OK',
          'delete_country must return OK for an existing country'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_country'
       );

SELECT is((SELECT COUNT(*)::text FROM events.Country WHERE name = 'TestCountry'),
          '0',
          'Country must be deleted from the table'
       );

-- Test case: country with regions
INSERT INTO events.Country (name)
VALUES ('TestCountryWithRegions');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountryWithRegions'));

SELECT is(events.delete_country((SELECT id FROM events.Country WHERE name = 'TestCountryWithRegions')),
          'ERROR: Country has related regions',
          'delete_country must return error for country with regions'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country has related regions',
          'Create log entry for country with regions'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;