\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_country';
SELECT is(events.update_country(1::smallint, 'NewCountry'),
          'ERROR: Procedure update_country is not registered in the procedures table',
          'Procedure update_country missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_country is not registered in the procedures table',
          'Create log entry for missing update_country procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_country', '');

-- Test case: not updating country with wrong ID
SELECT is(events.update_country(-1::smallint, 'NewCountry'),
          'ERROR: Country "-1" does not exist',
          'Update country that does not exist'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country "-1" does not exist',
          'Create log entry for not existing country id'
       );

-- Test case: Try to update country name with existing name country
INSERT INTO events.Country (name)
VALUES ('Country1');

WITH second_country AS (
    INSERT INTO events.Country (name)
        VALUES ('Country2')
        RETURNING id)

SELECT is(events.update_country((SELECT id FROM second_country)::smallint, 'Country1'),
          'ERROR: Country with name "Country1" already exists',
          'Error on country name already existing'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Country with name "Country1" already exists',
          'Create log entry for already existing country name'
       );

-- Test case: Update country name
WITH third_country AS (
    INSERT INTO events.Country (name)
        VALUES ('Country3')
        RETURNING id)

SELECT is(events.update_country((SELECT id FROM third_country)::smallint, 'TestCountry'),
          'OK',
          'Changed name of country'
       );

SELECT is((SELECT name FROM events.Country WHERE name = 'TestCountry'),
          'TestCountry',
          'Check if country name was changed'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for changing country name'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;