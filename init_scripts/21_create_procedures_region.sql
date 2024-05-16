\c event_database;

-- Create region
CREATE FUNCTION events.create_region(
    _name events.Region.name%type,
    _country_id events.Region.country_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Name: %s | Country ID: %s',
            _name,
            _country_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_region';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_region is not registered in the procedures table';
        END IF;

        INSERT INTO events.Region (name, country_id) VALUES (_name, _country_id);

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('Country "%s" does not exist', _country_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update region
CREATE FUNCTION events.update_region(
    _id events.Region.id%type,
    _name events.Region.name%type,
    _country_id events.Region.country_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s | Name: %s | Country ID: %s',
            _id,
            _name,
            _country_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_region';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_region is not registered in the procedures table';
        END IF;

        UPDATE events.Region
        SET name       = _name,
            country_id = _country_id
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Region "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Country "%s" does not exist', _country_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete region
CREATE FUNCTION events.delete_region(
    _id events.Region.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_region';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_region is not registered in the procedures table';
        END IF;

        DELETE FROM events.Region WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Region "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Region has related provinces';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;
