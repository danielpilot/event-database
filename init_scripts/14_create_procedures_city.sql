\c event_database;

-- Create city
CREATE FUNCTION events.create_city(
    _name events.City.name%type,
    _province_id events.City.province_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Name: %s | Province ID: %s',
            _name,
            _province_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_city';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_city is not registered in the procedures table';
        END IF;

        INSERT INTO events.City (name, province_id) VALUES (_name, _province_id);

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Province "%s" does not exist', _province_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update city
CREATE FUNCTION events.update_city(
    _id events.City.id%type,
    _name events.City.name%type,
    _province_id events.City.province_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s | Name: %s | Province ID: %s',
            _id,
            _name,
            _province_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_city';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_city is not registered in the procedures table';
        END IF;

        UPDATE events.City
        SET name        = _name,
            province_id = _province_id
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'City "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Province "%s" does not exist', _province_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete city
CREATE FUNCTION events.delete_city(
    _id events.City.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_city';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_city is not registered in the procedures table';
        END IF;

        DELETE FROM events.City WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'City "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: City has related locations';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;
