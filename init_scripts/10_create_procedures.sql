\c event_database;

-- Create location
CREATE FUNCTION events.create_location(
    _name events.location.name%type,
    _address events.location.address%type,
    _city_id events.location.city_id%type,
    _latitude events.location.latitude%type,
    _longitude events.location.longitude%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters :=
                    format(
                            'Name: %s|Address: %s|CityID: %s|Latitude: %s|Longitude: %s',
                            _name,
                            _address,
                            _city_id,
                            _latitude,
                            _longitude
                    );

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_location';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure create_location is not registered in the procedures table';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.city WHERE id = _city_id) THEN
                RAISE EXCEPTION 'City % does not exist', _city_id;
            END IF;

            INSERT INTO events.location (name, city_id, address, latitude, longitude)
            VALUES (_name, _city_id, _address, _latitude, _longitude);

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        END
    $$
LANGUAGE plpgsql;

-- Update location
CREATE FUNCTION events.update_location(
    _location_id events.location.id%type,
    _name events.location.name%type,
    _address events.location.address%type,
    _city_id events.location.city_id%type,
    _latitude events.location.latitude%type,
    _longitude events.location.longitude%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters :=
                    format(
                            'ID: %s|Name: %s|Address: %s|CityID: %s|Latitude: %s|Longitude: %s',
                            _location_id,
                            _name,
                            _address,
                            _city_id,
                            _latitude,
                            _longitude
                    );

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_location';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure update_location is not registered in the procedures table';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.location WHERE id = _location_id) THEN
                RAISE EXCEPTION 'Location % does not exist', _location_id;
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.city WHERE id = _city_id) THEN
                RAISE EXCEPTION 'City % does not exist', _city_id;
            END IF;

            UPDATE events.location
            SET name = _name, city_id = _city_id, address = _address, latitude = _latitude, longitude = _longitude
            WHERE id = _location_id;

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        END
    $$
LANGUAGE plpgsql;

-- Delete location
CREATE FUNCTION events.delete_location(
    _location_id events.location.id%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters := format('ID: %s', _location_id);

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_location';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure delete_location is not registered in the procedures table';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.location WHERE id = _location_id) THEN
                RAISE EXCEPTION 'Location % does not exist', _location_id;
            END IF;

            IF EXISTS (SELECT 1 FROM events.event WHERE location_id = _location_id) THEN
                RAISE EXCEPTION 'Location % has related events', _location_id;
            END IF;

            DELETE FROM events.location WHERE id = _location_id;

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

                INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
                VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

                RETURN _result;
        END
    $$
LANGUAGE plpgsql;

-- Create organizer
CREATE FUNCTION events.create_organizer(
    _name events.organizer.name%type,
    _email events.organizer.email%type,
    _type events.organizer.type%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters :=
                    format(
                            'Name: %s|Email: %s|Type: %s',
                            _name,
                            _email,
                            _type
                    );

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_organizer';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure create_organizer is not registered in the procedures table';
            END IF;

            IF _type NOT IN ('Company', 'Association', 'Foundation') THEN
                RAISE EXCEPTION 'Invalid organizer type';
            END IF;

            IF EXISTS (SELECT 1 FROM events.organizer WHERE email = _email) THEN
                RAISE EXCEPTION 'Email already exists';
            END IF;

            INSERT INTO events.organizer (name, email, type)
            VALUES (_name, _email, _type);

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        END
    $$
LANGUAGE plpgsql;

-- Update organizer
CREATE FUNCTION events.update_organizer(
    _organizer_id events.organizer.id%type,
    _name events.organizer.name%type,
    _email events.organizer.email%type,
    _type events.organizer.type%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters :=
                    format(
                            'ID: %s, Name: %s|Email: %s|Type: %s',
                            _organizer_id,
                            _name,
                            _email,
                            _type
                    );

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_organizer';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure update_organizer is not registered in the procedures table';
            END IF;

            IF _type NOT IN ('Company', 'Association', 'Foundation') THEN
                RAISE EXCEPTION 'Invalid organizer type';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.organizer WHERE id = _organizer_id) THEN
                RAISE EXCEPTION 'Organizer % does not exist', _organizer_id;
            END IF;

            IF EXISTS (SELECT 1 FROM events.organizer WHERE email = _email AND id <> _organizer_id) THEN
                RAISE EXCEPTION 'Email already assigned to another user';
            END IF;

            UPDATE events.organizer
            SET name = _name,
                email = _email,
                type = _type
            WHERE id = _organizer_id;

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        END
    $$
LANGUAGE plpgsql;

-- Delete organizer
CREATE FUNCTION events.delete_organizer(
    _organizer_id events.organizer.id%type
) RETURNS TEXT
AS
    $$
        DECLARE
            _entry_parameters VARCHAR(255);
            _procedure_id     INTEGER;
            _result           TEXT;
        BEGIN
            _entry_parameters := format('ID: %s',_organizer_id);

            SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_organizer';

            IF _procedure_id IS NULL THEN
                RAISE EXCEPTION 'Procedure delete_organizer is not registered in the procedures table';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM events.organizer WHERE id = _organizer_id) THEN
                RAISE EXCEPTION 'Organizer % does not exist', _organizer_id;
            END IF;

            DELETE FROM events.organizer WHERE id = _organizer_id;

            _result := 'OK';

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        EXCEPTION
            WHEN raise_exception THEN
                _result := format('ERROR: %s', SQLERRM);

            INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
            VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

            RETURN _result;
        END
    $$
LANGUAGE plpgsql;
