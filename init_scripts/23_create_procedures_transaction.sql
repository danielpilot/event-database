\c event_database;

-- Create transaction
CREATE FUNCTION events.create_transaction(
    _event_id events.Transaction.event_id%type,
    _user_id events.Transaction.user_id%type,
    _unit_price events.Transaction.unit_price%type,
    _quantity events.Transaction.quantity%type,
    _reference events.Transaction.reference%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
    _maximum_per_sale events.Event_With_Sales.maximum_per_sale%type;
    _event_has_sales  BOOLEAN;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s | Unit Price: %s | Quantity: %s | Reference: %s',
            _event_id,
            _user_id,
            _unit_price,
            _quantity,
            _reference);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'create_transaction';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_transaction is not registered in the procedures table';
        END IF;

        SELECT event.event_has_sales, events_with_sales.maximum_per_sale
        INTO _event_has_sales, _maximum_per_sale
        FROM events.Event_With_Sales events_with_sales
                 JOIN events.Event event ON events_with_sales.event_id = event.id
        WHERE events_with_sales.id = _event_id;

        IF _maximum_per_sale IS NULL OR _event_has_sales IS FALSE THEN
            RAISE EXCEPTION 'Event does not have sales enabled';
        END IF;

        IF _quantity > _maximum_per_sale THEN
            RAISE EXCEPTION 'Quantity "%" exceeds the maximum per sale limit', _quantity;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.User WHERE id = _user_id) THEN
            RAISE EXCEPTION 'User "%" does not exist', _user_id;
        END IF;

        IF EXISTS (SELECT 1 FROM events.transaction WHERE reference = _reference) THEN
            RAISE EXCEPTION 'Transaction with reference "%" already exists', _reference;
        END IF;


        INSERT INTO events.Transaction (event_id, user_id, unit_price, quantity, reference)
        VALUES (_event_id, _user_id, _unit_price, _quantity, _reference);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := 'ERROR: Transaction already exists';
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Update transaction
CREATE FUNCTION events.update_transaction(
    _event_id events.Transaction.event_id%TYPE,
    _user_id events.Transaction.user_id%TYPE,
    _unit_price events.Transaction.unit_price%TYPE,
    _quantity events.Transaction.quantity%TYPE,
    _reference events.Transaction.reference%TYPE
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters  TEXT;
    _procedure_id      INTEGER;
    _result            TEXT;
    _maximum_per_sale  events.Event_With_Sales.maximum_per_sale%type;
    _message_not_found TEXT;
BEGIN
    _entry_parameters := format(
            'Event ID: %s | User ID: %s | Unit Price: %s | Quantity: %s | Reference: %s',
            _event_id,
            _user_id,
            _unit_price,
            _quantity,
            _reference);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'update_transaction';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_transaction is not registered in the procedures table';
        END IF;

        SELECT maximum_per_sale
        INTO _maximum_per_sale
        FROM events.Event_With_Sales
        WHERE id = _event_id;

        IF _maximum_per_sale IS NULL THEN
            RAISE EXCEPTION 'Event does not have sales enabled';
        END IF;

        IF _quantity > _maximum_per_sale THEN
            RAISE EXCEPTION 'Quantity "%" exceeds the maximum per sale limit', _quantity;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM events.User WHERE id = _user_id) THEN
            RAISE EXCEPTION 'User "%" does not exist', _user_id;
        END IF;

        UPDATE events.Transaction
        SET unit_price = _unit_price,
            quantity   = _quantity,
            reference  = _reference
        WHERE event_id = _event_id
          AND user_id = _user_id;

        IF NOT FOUND THEN
            _message_not_found = 'Transaction does not exist';
            RAISE EXCEPTION '%', _message_not_found;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Transaction with reference "%s" already exists', _reference);
        WHEN OTHERS THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END;
$$ LANGUAGE plpgsql;

-- Delete transaction
CREATE FUNCTION events.delete_transaction(
    _event_id events.Transaction.event_id%TYPE,
    _user_id events.Transaction.user_id%TYPE
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
        SELECT id INTO _procedure_id FROM logs.Procedure WHERE name = 'delete_transaction';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_transaction is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.Transaction
        WHERE event_id = _event_id
          AND user_id = _user_id;

        IF NOT FOUND THEN
            _message_not_found = format('Transaction for event "%s" and user "%s" does not exist', _event_id, _user_id);
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
