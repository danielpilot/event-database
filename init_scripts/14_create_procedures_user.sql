\c event_database;

-- Create user
CREATE FUNCTION events.create_user(
    _name events.User.name%type,
    _surname events.User.surname%type,
    _email events.User.email%type,
    _password events.User.password%type,
    _roles events.User.roles%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('Name: %s | Surname: %s | Email: %s | Roles: %s', _name, _surname, _email, _roles);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_user';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_user is not registered in the procedures table';
        END IF;

        INSERT INTO events.User (name, surname, email, password, roles)
        VALUES (_name, _surname, _email, _password, _roles);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: User with email "%s" already exists', _email);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Update user
CREATE FUNCTION events.update_user(
    _id events.User.id%type,
    _name events.User.name%type,
    _surname events.User.surname%type,
    _email events.User.email%type,
    _password events.User.password%type,
    _roles events.User.roles%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format(
            'ID: %s | Name: %s | Surname: %s | Email: %s | Password: %s | Roles: %s',
            _id,
            _name,
            _surname,
            _email,
            _password,
            _roles);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_user';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_user is not registered in the procedures table';
        END IF;

        UPDATE events.User
        SET name     = _name,
            surname  = _surname,
            email    = _email,
            password = _password,
            roles    = _roles
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'User "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: User with email "%s" already exists', _email);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Delete user
CREATE FUNCTION events.delete_user(
    _id events.User.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_user';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_user is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.User
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'User "%" does not exist', _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: User has related transactions';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;
