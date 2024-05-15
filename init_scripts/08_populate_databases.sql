\c event_database;

-- Load initial countries
INSERT INTO events.country (name) VALUES ('Spain');

-- Load initial regions
INSERT INTO events.region (name, country_id) VALUES ('Madrid', 1),
                                                    ('Galicia', 1),
                                                    ('Cataluña', 1);

-- Load initial provinces
INSERT INTO events.province (name, region_id) VALUES ('Madrid', 1),
                                                     ('Pontevedra', 2),
                                                     ('A Coruña', 2),
                                                     ('Lugo', 2),
                                                     ('Ourense', 2),
                                                     ('Barcelona', 3),
                                                     ('Girona', 3),
                                                     ('Lleida', 3),
                                                     ('Tarragona', 3);

-- Load initial cities
INSERT INTO events.city (name, province_id) VALUES ('Madrid', 1),
                                                   ('Barcelona', 6),
                                                   ('Vigo', 2);

-- Load initial procedures
INSERT INTO logs.Procedures (name, description) VALUES ('create_location', 'Creates a new location'),
                                                       ('update_location', 'Updates a location'),
                                                       ('delete_location', 'Deletes a location');
