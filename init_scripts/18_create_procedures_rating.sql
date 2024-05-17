\c event_database;

-- Create rating
CREATE FUNCTION events.create_rating(
    _event_id events.Rating.event_id%type,
    _user_id events.Rating.user_id%type,
    _punctuation events.Rating.punctuation%type,
    _comment events.Rating.comment%type,
    _published events.Rating.published %type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s | Punctuation: %s | Comment: %s | Published: %s',
            _event_id,
            _user_id,
            _punctuation,
            _comment,
            _published);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_rating';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_rating is not registered in the procedures table';
        END IF;

        IF _punctuation > 5 THEN
            RAISE EXCEPTION 'Punctuation should be less than or equal to 5';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.Event WHERE id = _event_id) THEN
            RAISE EXCEPTION 'Event "%" does not exist', _event_id;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.User WHERE id = _user_id) THEN
            RAISE EXCEPTION 'User "%" does not exist', _user_id;
        END IF;

        INSERT INTO events.rating (event_id, user_id, punctuation, comment, published)
        VALUES (_event_id, _user_id, _punctuation, _comment, _published);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('A rating already exists for user "%s" in event "%s"', _user_id, _event_id);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update rating
CREATE FUNCTION events.update_rating(
    _event_id events.Rating.event_id%type,
    _user_id events.Rating.user_id%type,
    _punctuation events.Rating.punctuation%type,
    _comment events.Rating.comment%type,
    _published events.Rating.published %type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters  TEXT;
    _procedure_id      INTEGER;
    _result            TEXT;
    _message_not_found TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s | Punctuation: %s | Comment: %s | Published: %s',
            _event_id,
            _user_id,
            _punctuation,
            _comment,
            _published);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_rating';

        IF _punctuation > 5 THEN
            RAISE EXCEPTION 'Punctuation should be less than or equal to 5';
        END IF;

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_rating is not registered in the procedures table';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.Event WHERE id = _event_id) THEN
            RAISE EXCEPTION 'Event "%" does not exist', _event_id;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.User WHERE id = _user_id) THEN
            RAISE EXCEPTION 'User "%" does not exist', _user_id;
        END IF;

        UPDATE events.rating
        SET punctuation = _punctuation,
            comment     = _comment,
            published   = _published
        WHERE event_id = _event_id
          AND user_id = _user_id;

        IF NOT FOUND THEN
            _message_not_found = format('Rating for event "%s" and user "%s" does not exist', _event_id, _user_id);
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

-- Delete rating
CREATE FUNCTION events.delete_rating(
    _event_id events.Rating.event_id%type,
    _user_id events.Rating.user_id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters  TEXT;
    _procedure_id      INTEGER;
    _result            TEXT;
    _message_not_found TEXT;

BEGIN
    _entry_parameters := format('Event ID: %s | User ID: %s', _event_id, _user_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_rating';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_rating is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.Rating
        WHERE event_id = _event_id
          AND user_id = _user_id;

        IF NOT FOUND THEN
            _message_not_found = format('Rating for event "%s" and user "%s" does not exist', _event_id, _user_id);
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
END
$$ LANGUAGE plpgsql;
