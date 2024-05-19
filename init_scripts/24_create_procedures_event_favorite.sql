\c event_database;

-- Create event favorite
CREATE FUNCTION events.create_event_favorite(
    _event_id events.Event_Favorite.event_id%type,
    _user_id events.Event_Favorite.user_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s',
            _event_id,
            _user_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_event_favorite';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_event_favorite is not registered in the procedures table';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.Event WHERE id = _event_id) THEN
            RAISE EXCEPTION 'Event "%" does not exist', _event_id;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.User WHERE id = _user_id) THEN
            RAISE EXCEPTION 'User "%" does not exist', _user_id;
        END IF;

        INSERT INTO events.Event_Favorite (event_id, user_id) VALUES (_event_id, _user_id);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Favorite of user "%s" for event "%s" already exists', _user_id, _event_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete event favorite
CREATE FUNCTION events.delete_event_favorite(
    _event_id events.Event_Favorite.event_id%type,
    _user_id events.Event_Favorite.user_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters  TEXT;
    _procedure_id      INTEGER;
    _result            TEXT;
    _message_not_found TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s',
            _event_id,
            _user_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_event_favorite';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_event_favorite is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.Event_Favorite
        WHERE event_id = _event_id
          AND user_id = _user_id;

        IF NOT FOUND THEN
            _message_not_found = format('Favorite for event "%s" and user "%s" does not exist', _event_id, _user_id);
            RAISE EXCEPTION '%', _message_not_found;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;