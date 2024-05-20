\c event_database;

-- Create province
CREATE FUNCTION events.create_province(
    _name events.Province.name%type,
    _region_id events.Province.region_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Name: %s | Region ID: %s',
            _name,
            _region_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_province';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_province is not registered in the procedures table';
        END IF;

        INSERT INTO events.Province (name, region_id) VALUES (_name, _region_id);

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Region "%s" does not exist', _region_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update province
CREATE FUNCTION events.update_province(
    _id events.Province.id%type,
    _name events.Province.name%type,
    _region_id events.Province.region_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s | Name: %s | Region ID: %s',
            _id,
            _name,
            _region_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_province';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_province is not registered in the procedures table';
        END IF;

        UPDATE events.Province
        SET name      = _name,
            region_id = _region_id
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Province "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Region "%s" does not exist', _region_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete province
CREATE FUNCTION events.delete_province(
    _id events.Province.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_province';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_province is not registered in the procedures table';
        END IF;

        DELETE FROM events.Province WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Province "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Province has related cities';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;
