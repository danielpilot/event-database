\c event_database;

-- Load initial countries
INSERT INTO events.Country (name) VALUES ('Spain');

-- Load initial regions
INSERT INTO events.Region (name, country_id) VALUES ('Madrid', 1),
                                                    ('Galicia', 1),
                                                    ('Cataluña', 1);

-- Load initial provinces
INSERT INTO events.Province (name, region_id) VALUES ('Madrid', 1),
                                                     ('Pontevedra', 2),
                                                     ('A Coruña', 2),
                                                     ('Lugo', 2),
                                                     ('Ourense', 2),
                                                     ('Barcelona', 3),
                                                     ('Girona', 3),
                                                     ('Lleida', 3),
                                                     ('Tarragona', 3);

-- Load initial cities
INSERT INTO events.City (name, province_id) VALUES ('Madrid', 1),
                                                   ('Barcelona', 6),
                                                   ('Vigo', 2);

-- Load initial procedures
INSERT INTO logs.Procedures (name, description) VALUES ('create_location', 'Creates a new location'),
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
                                                       ('delete_transaction', 'Deletes a transaction');
