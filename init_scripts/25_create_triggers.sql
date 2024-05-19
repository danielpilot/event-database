\c event_database;

-- Check event capacity before insert
CREATE FUNCTION events.check_transaction_conditions_before_insert() RETURNS trigger AS
$$
DECLARE
    _capacity           SMALLINT;
    _sales              SMALLINT;
    _event_id           INTEGER;
    _available_capacity INTEGER;
    _event_has_sales    BOOLEAN;
BEGIN
    SELECT ews.capacity, ews.sales, ews.event_id
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
EXECUTE PROCEDURE events.check_transaction_conditions_before_insert();

-- Check event capacity on update
CREATE FUNCTION events.check_transaction_conditions_before_update() RETURNS trigger AS
$$
DECLARE
    _capacity           SMALLINT;
    _sales              SMALLINT;
    _event_id           INTEGER;
    _available_capacity INTEGER;
    _event_has_sales    BOOLEAN;
    _quantity_variation INTEGER;
BEGIN
    SELECT ews.capacity, ews.sales, ews.event_id
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
EXECUTE PROCEDURE events.check_transaction_conditions_before_update();

-- Update sales after insert
CREATE FUNCTION events.update_sales_after_insert() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales + NEW.quantity
    WHERE id = NEW.event_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_insert
    AFTER INSERT
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_sales_after_insert();

-- Update sales after update
CREATE FUNCTION events.update_sales_after_update() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales + NEW.quantity - OLD.quantity
    WHERE id = NEW.event_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_update
    AFTER UPDATE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_sales_after_update();

-- Delete sales after delete
CREATE FUNCTION events.update_sales_after_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE events.event_with_sales
    SET sales = sales - OLD.quantity
    WHERE id = OLD.event_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_after_delete
    AFTER DELETE
    ON events.transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_sales_after_delete();

-- Disable the event sales when conditions are met
CREATE FUNCTION events.check_event_sales_status() RETURNS TRIGGER AS
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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_event_sales_status
    AFTER INSERT OR UPDATE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.check_event_sales_status();

-- Add event change on event modification
CREATE FUNCTION events.add_event_change_on_event_modification() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.start_date > OLD.start_date THEN
        CALL events.create_event_change(
                NEW.id,
                'Delayed',
                NOW(),
                format('The event has been delayed from %s to %s', OLD.start_date, NEW.start_date)
             );
    ELSIF NEW.start_date < OLD.start_date THEN
        CALL events.create_event_change(
                NEW.id,
                'Other',
                NOW(),
                format('The event has been advanced from %s to %s', OLD.start_date, NEW.start_date)
             );
    END IF;

    IF NEW.location_id != OLD.location_id THEN
        CALL events.create_event_change(
                NEW.id,
                'Location Change',
                NOW(),
                format('The event has been moved from location "%s" to "%s"', OLD.location_id, NEW.location_id)
             );
    END IF;

    IF NEW.price != OLD.price THEN
        CALL events.create_event_change(
                NEW.id,
                'Price Change',
                NOW(),
                format('The event price has changed from "%s" to "%s"', OLD.price, NEW.price)
             );
    END IF;

    IF NOT NEW.event_status AND NEW.event_status != OLD.event_status THEN
        CALL events.create_event_change(
                NEW.id,
                'Cancelled',
                NOW(),
                'Event has been cancelled'
             );
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_add_event_change_on_event_modification
    AFTER UPDATE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.add_event_change_on_event_modification();
