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
            _city_exists      BOOLEAN;
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

            SELECT EXISTS (SELECT 1 FROM events.city WHERE id = _city_id) INTO _city_exists;

            IF NOT _city_exists THEN
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
            _location_exists  BOOLEAN;
            _city_exists      BOOLEAN;
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

            SELECT EXISTS (SELECT 1 FROM events.location WHERE id = _location_id) INTO _location_exists;

            IF NOT _location_exists THEN
                RAISE EXCEPTION 'Location % does not exist', _location_id;
            END IF;

            SELECT EXISTS (SELECT 1 FROM events.city WHERE id = _city_id) INTO _city_exists;

            IF NOT _city_exists THEN
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
