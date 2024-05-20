\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_city';
SELECT is(events.update_city(1, 'UpdatedCity', 1::integer),
          'ERROR: Procedure update_city is not registered in the procedures table',
          'Procedure update_city missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_city is not registered in the procedures table',
          'Create log entry for missing update_city procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_city', '');


-- Test case: city update with non-existing ID
SELECT is(events.update_city(-1::integer, 'UpdatedCity', 1::integer),
          'ERROR: City "-1" does not exist',
          'update_city must return error for non-existing city id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: City "-1" does not exist',
          'Create log entry for non-existing city id'
       );

-- Test case: city update with non-existing province ID
INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

SELECT is(events.update_city(
                  (SELECT id FROM events.City WHERE name = 'TestCity'),
                  'UpdatedCity',
                  -1::integer
          ),
          'ERROR: Province "-1" does not exist',
          'update_city must return error for non-existing province id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Province "-1" does not exist',
          'Create log entry for non-existing province id'
       );

-- Test case: successful city update
SELECT is(events.update_city(
                  (SELECT id FROM events.City WHERE name = 'TestCity'),
                  'UpdatedCity',
                  (SELECT id FROM events.Province WHERE name = 'TestProvince')
          ),
          'OK',
          'update_city must return OK for an existing city'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_city'
       );

-- Check if the city was properly updated
SELECT is((SELECT name FROM events.City WHERE name = 'UpdatedCity'),
          'UpdatedCity',
          'City must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;