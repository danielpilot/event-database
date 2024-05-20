\c event_database;

-- Create country
CREATE FUNCTION events.create_country(
    _name events.Country.name%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('Name: %s', _name);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_country';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_country is not registered in the procedures table';
        END IF;

        INSERT INTO events.Country (name) VALUES (_name);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Country with name "%s" already exists', _name);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update country
CREATE FUNCTION events.update_country(
    _id events.Country.id%type,
    _name events.Country.name%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s | Name: %s',
            _id,
            _name);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_country';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_country is not registered in the procedures table';
        END IF;

        UPDATE events.Country
        SET name = _name
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Country "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Country with name "%s" already exists', _name);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete country
CREATE FUNCTION events.delete_country(
    _id events.Country.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_country';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_country is not registered in the procedures table';
        END IF;

        DELETE FROM events.Country WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Country "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Country has related regions';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;
