\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'delete_category';
SELECT is(events.delete_category(1::integer),
          'ERROR: Procedure delete_category is not registered in the procedures table',
          'Procedure delete_category missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure delete_category is not registered in the procedures table',
          'Create log entry for missing delete_category procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('delete_category', '');

-- Test case: category deletion with non-existing ID
SELECT is(events.delete_category(-1::integer),
          'ERROR: Category with ID "-1" does not exist',
          'delete_category must return error for non-existing category id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category with ID "-1" does not exist',
          'Create log entry for non-existing category id'
       );

-- Test case: successful category deletion
INSERT INTO events.Category (name, parent_category)
VALUES ('TestCategory', NULL);

SELECT is(events.delete_category((SELECT id FROM events.Category WHERE name = 'TestCategory')),
          'OK',
          'delete_category must return OK for a valid category deletion'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for delete_category'
       );

-- Check if the category was properly deleted
SELECT is((SELECT COUNT(*)::text FROM events.Category WHERE name = 'TestCategory'),
          '0',
          'Category must be deleted from the table'
       );

-- Test case: category delete with related events
INSERT INTO events.organizer (name, email, type)
VALUES ('TestOrganizer', 'test@organizer.com', 'Company');

INSERT INTO events.Country (name)
VALUES ('TestCountry');

INSERT INTO events.Region (name, country_id)
VALUES ('TestRegion', (SELECT id FROM events.Country WHERE name = 'TestCountry'));

INSERT INTO events.Province (name, region_id)
VALUES ('TestProvince', (SELECT id FROM events.Region WHERE name = 'TestRegion'));

INSERT INTO events.City (name, province_id)
VALUES ('TestCity', (SELECT id FROM events.Province WHERE name = 'TestProvince'));

INSERT INTO events.Location (name, address, city_id, latitude, longitude)
VALUES ('TestLocation', 'TestAddress', (SELECT id FROM events.City WHERE name = 'TestCity'), 0.0, 0.0);

INSERT INTO events.Event (name,
                          start_date,
                          end_date,
                          schedule,
                          description,
                          price,
                          event_status,
                          event_published,
                          event_has_sales,
                          comments,
                          organizer_id,
                          location_id)
VALUES ('TestEvent',
        NOW(),
        NOW(),
        '',
        '',
        0.0,
        false,
        false,
        false,
        false,
        (SELECT id FROM events.organizer WHERE name = 'TestOrganizer'),
        (SELECT id FROM events.Location WHERE name = 'TestLocation'));

INSERT INTO events.Category (name, parent_category)
VALUES ('TestCategory', NULL);

INSERT INTO events.Event_has_Category (event_id, category_id)
VALUES ((SELECT id FROM events.Event WHERE name = 'TestEvent'),
        (SELECT id FROM events.Category WHERE name = 'TestCategory')
       );

SELECT is(events.delete_category((SELECT id FROM events.Category WHERE name = 'TestCategory')),
          'ERROR: Category has related events',
          'delete_category must return error for category with related events'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category has related events',
          'Create log entry for category with related events'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
