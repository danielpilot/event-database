\c event_database;

-- Create organizer
CREATE FUNCTION events.create_organizer(
    _name events.organizer.name%type,
    _email events.organizer.email%type,
    _type events.organizer.type%type
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
                    'Name: %s | Email: %s | Type: %s',
                    _name,
                    _email,
                    _type
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_organizer';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_organizer is not registered in the procedures table';
        END IF;

        INSERT INTO events.organizer (name, email, type)
        VALUES (_name, _email, _type);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Email "%s" already exists', _email);
        WHEN check_violation THEN
            _result := format('ERROR: Invalid organizer type "%s"', _type);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Update organizer
CREATE FUNCTION events.update_organizer(
    _id events.organizer.id%type,
    _name events.organizer.name%type,
    _email events.organizer.email%type,
    _type events.organizer.type%type
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
                    'ID: %s, Name: %s | Email: %s | Type: %s',
                    _id,
                    _name,
                    _email,
                    _type
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_organizer';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_organizer is not registered in the procedures table';
        END IF;

        UPDATE events.organizer
        SET name  = _name,
            email = _email,
            type  = _type
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Organizer "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Email "%s" already assigned to another user', _email);
        WHEN check_violation THEN
            _result := format('ERROR: Invalid organizer type "%s"', _type);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Delete organizer
CREATE FUNCTION events.delete_organizer(
    _id events.organizer.id%type
) RETURNS TEXT
AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_organizer';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_organizer is not registered in the procedures table';
        END IF;

        DELETE FROM events.organizer WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Organizer "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Organizer has related events';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;
