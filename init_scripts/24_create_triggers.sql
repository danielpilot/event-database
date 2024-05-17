\c event_database;

-- Check event capacity before insert
CREATE FUNCTION check_transaction_conditions_before_insert() RETURNS trigger AS
$$
DECLARE
    _capacity           SMALLINT;
    _sales              SMALLINT;
    _event_id           INTEGER;
    _available_capacity INTEGER;
    _event_has_sales    BOOLEAN;
BEGIN
    SELECT (ews.capacity, ews.sales, ews.event_id)
    INTO _capacity, _sales, _event_id
    FROM events.Event_With_Sales ews
    WHERE id = NEW.event_id;

    _available_capacity := _capacity - _sales;

    IF NEW.quantity > _available_capacity THEN
        RAISE EXCEPTION 'Not enough tickets are available';
    END IF;

    SELECT e.event_has_sales INTO _event_has_sales FROM events.Event e WHERE id = _event_id;

    IF NOT _event_has_sales THEN
        RAISE EXCEPTION 'Event sales are closed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_transaction_conditions_before_insert
    BEFORE INSERT
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE check_transaction_conditions_before_insert();

-- Check event capacity on update
CREATE FUNCTION check_transaction_conditions_before_update() RETURNS trigger AS
$$
DECLARE
    _capacity           SMALLINT;
    _sales              SMALLINT;
    _event_id           INTEGER;
    _available_capacity INTEGER;
    _event_has_sales    BOOLEAN;
    _quantity_variation INTEGER;
BEGIN
    SELECT (ews.capacity, ews.sales, ews.event_id)
    INTO _capacity, _sales, _event_id
    FROM events.Event_With_Sales ews
    WHERE id = NEW.event_id;

    _available_capacity := _capacity - _sales;
    _quantity_variation := NEW.quantity - OLD.quantity;

    IF _quantity_variation > _available_capacity THEN
        RAISE EXCEPTION 'Not enough tickets are available';
    END IF;

    SELECT e.event_has_sales INTO _event_has_sales FROM events.Event e WHERE id = _event_id;

    IF NOT _event_has_sales THEN
        RAISE EXCEPTION 'Event sales are closed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_transaction_conditions_before_update
    BEFORE UPDATE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE check_transaction_conditions_before_update();
