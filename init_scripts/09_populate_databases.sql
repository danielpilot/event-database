\c event_database;

-- Load initial procedures
INSERT INTO logs.Procedure (name, description)
VALUES ('create_location', 'Creates a new location'),
       ('update_location', 'Updates a location'),
       ('delete_location', 'Deletes a location'),
       ('create_organizer', 'Creates a new organizer'),
       ('update_organizer', 'Updates an organizer'),
       ('delete_organizer', 'Delete an organizer'),
       ('create_organizer_contact', 'Creates a new organizer contact'),
       ('update_organizer_contact', 'Updates an organizer contact'),
       ('delete_organizer_contact', 'Delete an organizer contact'),
       ('create_category', 'Creates a new category'),
       ('update_category', 'Updates a category'),
       ('delete_category', 'Delete a category'),
       ('create_user', 'Creates a new user'),
       ('update_user', 'Updates a user'),
       ('delete_user', 'Delete a user'),
       ('create_event', 'Creates a new event'),
       ('update_event', 'Updates an event'),
       ('delete_event', 'Delete an event'),
       ('create_event_change', 'Creates a new event change'),
       ('update_event_change', 'Updates an event change'),
       ('delete_event_change', 'Delete an event change'),
       ('create_rating', 'Creates a new rating'),
       ('update_rating', 'Updates a rating'),
       ('delete_rating', 'Delete a rating'),
       ('create_transaction', 'Creates a new transaction'),
       ('update_transaction', 'Updates a transaction'),
       ('delete_transaction', 'Deletes a transaction'),
       ('create_event_favorite', 'Creates a new event favorite'),
       ('delete_event_favorite', 'Deletes an event favorite'),
       ('create_country', 'Creates a new country'),
       ('update_country', 'Updates a country'),
       ('delete_country', 'Deletes a country'),
       ('create_region', 'Creates a new region'),
       ('update_region', 'Updates a region'),
       ('delete_region', 'Deletes a region'),
       ('create_province', 'Creates a new province'),
       ('update_province', 'Updates a province'),
       ('delete_province', 'Deletes a province'),
       ('create_city', 'Creates a new city'),
       ('update_city', 'Updates a city'),
       ('delete_city', 'Deletes a city');

-- Load initial system counters
INSERT INTO statistics.system_counters (name, value)
VALUES ('non_admin_users', 0),
       ('total_events', 0),
       ('total_payed_events', 0),
       ('total_transactions', 0);

-- Load initial percentage indicator list
INSERT INTO statistics.percentage_indicators (indicator, value)
VALUES (1, 0.0),
       (2, 0.0),
       (3, 0.0),
       (4, 0.0),
       (5, 0.0),
       (6, 0.0),
       (7, 0.0),
       (8, 0.0);

-- Load initial integer indicator list
INSERT INTO statistics.integer_indicators (indicator, value)
VALUES (1, 0);
