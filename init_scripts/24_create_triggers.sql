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

    RETURN NULL;
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

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_transaction_conditions_before_update
    BEFORE UPDATE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE check_transaction_conditions_before_update();

-- Update sales after insert
CREATE FUNCTION update_sales_after_insert() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales + NEW.quantity
    WHERE id = NEW.event_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_insert
    AFTER INSERT
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE update_sales_after_insert();

-- Update sales after update
CREATE FUNCTION update_sales_after_update() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales + NEW.quantity - OLD.quantity
    WHERE id = NEW.event_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_update
    AFTER UPDATE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE update_sales_after_update();

-- Delete sales after delete
CREATE FUNCTION update_sales_after_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales - OLD.quantity
    WHERE id = OLD.event_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_delete
    AFTER DELETE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE update_sales_after_delete();

-- Disable the event sales when conditions are met
CREATE FUNCTION check_event_sales_status() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT NEW.event_has_sales THEN
        RETURN NULL;
    END IF;

    IF NOT NEW.event_published OR NOT NEW.event_status THEN
        UPDATE events.event
        SET event_has_sales = false
        WHERE id = NEW.id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_event_sales_status
    AFTER INSERT OR UPDATE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE check_event_sales_status();
