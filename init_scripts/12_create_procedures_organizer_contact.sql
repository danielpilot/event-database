\c event_database;

-- Create Organizer Contact
CREATE FUNCTION events.create_organizer_contact(
    _organizer_id events.organizer_contact.organizer_id%type,
    _name events.organizer_contact.name%type,
    _email events.organizer_contact.email%type,
    _telephone events.organizer_contact.telephone%type
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
                    'Organizer ID: %s | Name: %s | Email: %s | Telephone: %s',
                    _organizer_id,
                    _name,
                    _email,
                    _telephone
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_organizer_contact';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_organizer_contact is not registered in the procedures table';
        END IF;

        INSERT INTO events.organizer_contact (name, organizer_id, email, telephone)
        VALUES (_name, _organizer_id, _email, _telephone);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Email "%s" already exists', _email);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Update organizer contact
CREATE FUNCTION events.update_organizer_contact(
    _organizer_id events.organizer_contact.organizer_id%type,
    _name events.organizer_contact.name%type,
    _email events.organizer_contact.email%type,
    _telephone events.organizer_contact.telephone%type
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
                    'Organizer ID: %s | Name: %s | Email: %s | Telephone: %s',
                    _organizer_id,
                    _name,
                    _email,
                    _telephone
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_organizer_contact';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_organizer_contact is not registered in the procedures table';
        END IF;

        UPDATE events.organizer_contact
        SET email     = _email,
            telephone = _telephone
        WHERE name = _name
          AND organizer_id = _organizer_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Organizer contact does not exist';
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Email "%s" already assigned to another user', _email);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Delete organizer contact
CREATE FUNCTION events.delete_organizer_contact(
    _id events.organizer_contact.organizer_id%type,
    _name events.organizer_contact.name%type
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
                    'ID: %s | Name: %s',
                    _id,
                    _name
            );

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_organizer_contact';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_organizer_contact is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.organizer_contact
        WHERE name = _name
          AND organizer_id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Organizer contact "%" does not exist', _id;
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
