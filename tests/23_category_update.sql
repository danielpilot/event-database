\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(13);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'update_category';
SELECT is(events.update_category(1::integer, 'UpdatedCategory', NULL),
          'ERROR: Procedure update_category is not registered in the procedures table',
          'Procedure update_category missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_category is not registered in the procedures table',
          'Create log entry for missing update_category procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_category', '');

-- Test case: category update with non-existing ID
SELECT is(events.update_category(-1::integer, 'UpdatedCategory', NULL),
          'ERROR: Category "-1" does not exist',
          'update_category must return error for non-existing category id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category "-1" does not exist',
          'Create log entry for non-existing category id'
       );

-- Test case: category update with existing name under specified parent
INSERT INTO events.Category (name, parent_category)
VALUES ('ExistingCategory', NULL);

INSERT INTO events.Category (name, parent_category)
VALUES ('TestCategory', NULL);

SELECT is(events.update_category(
                  (SELECT id FROM events.category WHERE name = 'TestCategory' AND parent_category IS NULL),
                  'ExistingCategory',
                  NULL
          ),
          'ERROR: Category with name "ExistingCategory" already exists under specified parent',
          'update_category must return error for existing category name under specified parent'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category with name "ExistingCategory" already exists under specified parent',
          'Create log entry for existing category name under specified parent'
       );

-- Test case: category update with non-existing parent category
SELECT is(events.update_category(
                  (SELECT id FROM events.category WHERE name = 'TestCategory' AND parent_category IS NULL),
                  'UpdatedCategory',
                  -1::integer
          ),
          'ERROR: Category parent with ID "-1" not found',
          'update_category must return error on non-existing parent id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category parent with ID "-1" not found',
          'Create log entry for non-existing parent id'
       );

-- Test case: category update with self parent category
SELECT is(events.update_category(
                  (SELECT id FROM events.category WHERE name = 'TestCategory' AND parent_category IS NULL),
                  'UpdatedCategory',
                  (SELECT id FROM events.category WHERE name = 'TestCategory' AND parent_category IS NULL)
          ),
          'ERROR: A category cannot be its own parent',
          'update_category must return error on self parent id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: A category cannot be its own parent',
          'Create log entry for self parent id'
       );

-- Test case: successful category update
SELECT is(events.update_category(
                  (SELECT id FROM events.category WHERE name = 'TestCategory' AND parent_category IS NULL),
                  'UpdatedCategory',
                  NULL
          ),
          'OK',
          'update_category must return OK for a valid category update'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for update_category'
       );

-- Check if the category was properly updated
SELECT is((SELECT name FROM events.category WHERE name = 'UpdatedCategory' AND parent_category IS NULL),
          'UpdatedCategory',
          'Category must be updated in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;