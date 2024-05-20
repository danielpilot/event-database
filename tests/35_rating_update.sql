\c event_database;

SET SEARCH_PATH TO public, events;

BEGIN;
SELECT plan(13);

-- Test case: checking if the update_rating procedure is registered in the procedures table
DELETE
FROM logs.Procedure
WHERE name = 'update_rating';
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Procedure update_rating is not registered in the procedures table',
          'Procedure update_rating missing from the procedures table'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Procedure update_rating is not registered in the procedures table',
          'Create log entry for missing update_rating procedure'
       );

INSERT INTO logs.procedure (name, description)
VALUES ('update_rating', '');

-- Test case: updating a rating for a non-existent event
SELECT is(events.update_rating(
                  -1::integer,
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Event "-1" does not exist',
          'update_rating must return error for non-existent event'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Event "-1" does not exist',
          'Create log entry for non-existent event'
       );

-- Test case: updating a rating with an invalid user
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  -1::integer,
                  4::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: User "-1" does not exist',
          'update_rating must return error for non-existent user');

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: User "-1" does not exist',
          'Create log entry for non-existent user'
       );

-- Test case: updating a rating with a punctuation greater than 5
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  6::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'update_rating must return error on punctuation greater than 5'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for punctuation greater than 5'
       );

-- Test case: updating a rating with a punctuation smaller than 0
SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  6::smallint,
                  'UpdatedComment',
                  true
          ),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'create_rating must return error on punctuation smaller than 0'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'ERROR: Punctuation must be less than or equal to 5 and greater than 0',
          'Create log entry for punctuation smaller than 0'
       );

-- Test case: successful rating update
INSERT INTO events.rating(event_id, user_id, punctuation, comment, published)
VALUES ((SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
        (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
        4,
        'UpdatedComment',
        true);

SELECT is(events.update_rating(
                  (SELECT id::integer FROM events.Event WHERE name = 'TestEvent' LIMIT 1),
                  (SELECT id::integer FROM events.User WHERE email = 'test@test.com' LIMIT 1),
                  3::smallint,
                  'UpdatedComment',
                  true
          ),
          'OK',
          'update_rating must return OK for a valid rating update'
       );

SELECT is((SELECT result FROM logs.Log ORDER BY id DESC LIMIT 1),
          'OK',
          'Create log entry for valid rating update'
       );

SELECT is((SELECT COUNT(*)::text
           FROM events.Rating
           WHERE event_id = (SELECT id FROM events.Event WHERE name = 'TestEvent')
             AND punctuation = 3
             AND comment = 'UpdatedComment'),
          '1',
          'Rating must be updated in the Rating table'
       );

-- Finish the test
SELECT *
FROM finish();

ROLLBACK;