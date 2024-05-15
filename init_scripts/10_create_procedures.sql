\c event_database;

-- Create location
CREATE OR REPLACE FUNCTION events.create_location(
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
