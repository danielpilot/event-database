\c event_database;

-- Create event change
CREATE FUNCTION events.create_event_change(
    _event_id events.Event_Change.event_id%type,
    _type events.Event_Change.type%type,
    _date events.Event_Change.date%type,
    _description events.Event_Change.description %type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | Type: %s | Date: %s | Description: %s',
            _event_id,
            _type,
            _date,
            _description);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_event_change';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_event_change is not registered in the procedures table';
        END IF;

        INSERT INTO events.Event_Change (event_id, type, date, description)
        VALUES (_event_id, _type, _date, _description);

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Event does not exist';
        WHEN check_violation THEN
            _result := format('ERROR: Invalid event change type "%s"', _type);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update event change
CREATE FUNCTION events.update_event_change(
    _id events.Event_Change.id%type,
    _event_id events.Event_Change.event_id%type,
    _type events.Event_Change.type%type,
    _date events.Event_Change.date%type,
    _description events.Event_Change.description %type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s, Event ID: %s | Type: %s | Date: %s | Description: %s',
            _id,
            _event_id,
            _type,
            _date,
            _description);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_event_change';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_event_change is not registered in the procedures table';
        END IF;

        UPDATE events.Event_Change
        SET event_id    = _event_id,
            type        = _type,
            date        = _date,
            description = _description
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Event change "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Event does not exist';
        WHEN check_violation THEN
            _result := format('ERROR: Invalid event change type "%s"', _type);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete event change
CREATE FUNCTION events.delete_event_change(
    _id events.Event_Change.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_event_change';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_event_change is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.Event_Change
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Event change "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;
