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
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters :=
            format(
                    'Name: %s | Address: %s | City ID: %s | Latitude: %s | Longitude: %s',
                    _name,
                    _address,
                    _city_id,
                    _latitude,
                    _longitude
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_location';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_location is not registered in the procedures table';
        END IF;

        INSERT INTO events.location (name, city_id, address, latitude, longitude)
        VALUES (_name, _city_id, _address, _latitude, _longitude);

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: City "%s" does not exist', _city_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update location
CREATE FUNCTION events.update_location(
    _id events.location.id%type,
    _name events.location.name%type,
    _address events.location.address%type,
    _city_id events.location.city_id%type,
    _latitude events.location.latitude%type,
    _longitude events.location.longitude%type
) RETURNS TEXT
AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters :=
            format(
                    'ID: %s | Name: %s | Address: %s | City ID: %s | Latitude: %s | Longitude: %s',
                    _id,
                    _name,
                    _address,
                    _city_id,
                    _latitude,
                    _longitude
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_location';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_location is not registered in the procedures table';
        END IF;

        UPDATE events.location
        SET name      = _name,
            city_id   = _city_id,
            address   = _address,
            latitude  = _latitude,
            longitude = _longitude
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Location "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: City "%s" does not exist', _city_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters,
                          result)
    VALUES (NOW(), CURRENT_USER, _procedure_id,
            _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete location
CREATE FUNCTION events.delete_location(
    _id events.location.id%type
) RETURNS TEXT
AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_location';

    BEGIN
        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_location is not registered in the procedures table';
        END IF;

        DELETE FROM events.location WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Location "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Location has related events';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;
