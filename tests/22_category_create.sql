\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(9);

-- Test case: missing procedure entry
DELETE
from logs.procedure
WHERE name = 'create_category';
SELECT is(events.create_category('TestCategory', 1),
          'ERROR: Procedure create_category is not registered in the procedures table',
          'Procedure create_category missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure create_category is not registered in the procedures table',
          'Create log entry for missing create_category procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('create_category', '');

-- Test case: category creation with non-existing parent category ID
SELECT is(events.create_category('TestCategory', -1::integer),
          'ERROR: Category parent with ID "-1" not found',
          'create_category must return error for non-existing parent category id'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category parent with ID "-1" not found',
          'Create log entry for non-existing parent category id'
       );

-- Test case: category creation with existing name under specified parent
INSERT INTO events.Category (name, parent_category)
VALUES ('ExistingCategory', NULL);

SELECT is(events.create_category('ExistingCategory', NULL),
          'ERROR: Category with name "ExistingCategory" already exists under the specified parent',
          'create_category must return error for existing category name under specified parent'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Category with name "ExistingCategory" already exists under the specified parent',
          'Create log entry for existing category name under specified parent'
       );

-- Test case: successful category creation
SELECT is(events.create_category('TestCategory', NULL),
          'OK',
          'create_category must return OK for a valid category'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for create_category'
       );

-- Check if the category was properly created
SELECT is((SELECT name FROM events.Category WHERE name = 'TestCategory'),
          'TestCategory',
          'Category must be created in the table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;
