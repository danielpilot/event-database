\c event_database;

-- Create sales type to group sales parameters
CREATE TYPE events.event_sales_data AS
(
    capacity         SMALLINT,
    maximum_per_sale SMALLINT
);

-- Create event
CREATE FUNCTION events.create_event(
    _name events.Event.name%type,
    _start_date events.Event.start_date%type,
    _end_date events.Event.end_date%type,
    _schedule events.Event.schedule%type,
    _description events.Event.description%type,
    _price events.Event.price%type,
    _image events.Event.image%type,
    _event_status events.Event.event_status%type,
    _event_published events.Event.event_published%type,
    _comments events.Event.comments%type,
    _organizer_id events.Event.organizer_id%type,
    _location_id events.Event.location_id%type,
    _categories INT[],
    _event_sales_data events.event_sales_data DEFAULT NULL
) RETURNS TEXT AS
$$
DECLARE
    _inserted_event_id          INT;
    _entry_parameters           TEXT;
    _procedure_id               INTEGER;
    _result                     TEXT;
    _valid_categories_count     INTEGER;
    _category_id                INTEGER;
    _formatted_event_sales_data TEXT;
    _event_has_sales            BOOLEAN;
BEGIN
    _formatted_event_sales_data := 'NULL';

    IF _event_sales_data IS NOT NULL THEN
        _formatted_event_sales_data := format(
                'Capacity: %s - Maximum Per Sale: %s',
                _event_sales_data.capacity,
                _event_sales_data.maximum_per_sale);
    END IF;

    _entry_parameters := format(
            'Name: %s | Start Date: %s | End Date: %s | Schedule: %s | Description: %s | Price: %s | Image: %s | ' ||
            'Event Status: %s | Event Published: %s | Comments: %s | Organizer ID: %s | Location ID: %s' ||
            ' | Categories: %s | Event Sales Data: %s',
            _name,
            _start_date,
            _end_date,
            _schedule,
            _description,
            _price,
            _image,
            _event_status,
            _event_published,
            _comments,
            _organizer_id,
            _location_id,
            array_to_string(_categories::text[], ', '),
            _formatted_event_sales_data);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_event';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_event is not registered in the procedures table';
        END IF;

        -- Check that all categories exist
        SELECT COUNT(*)
        FROM events.Category
        WHERE id = ANY (_categories)
        INTO _valid_categories_count;

        IF _valid_categories_count < array_length(_categories, 1) THEN
            RAISE EXCEPTION 'Some categories do not exist';
        END IF;

        _event_has_sales := false;
        IF _event_sales_data IS NOT NULL THEN
            _event_has_sales := true;
        END IF;

        -- Create event
        INSERT INTO events.Event (name,
                                  start_date,
                                  end_date,
                                  schedule,
                                  description,
                                  price,
                                  image,
                                  event_status,
                                  event_published,
                                  event_has_sales,
                                  comments,
                                  organizer_id,
                                  location_id)
        VALUES (_name,
                _start_date,
                _end_date,
                _schedule,
                _description,
                _price,
                _image,
                _event_status,
                _event_published,
                _event_has_sales,
                _comments,
                _organizer_id,
                _location_id)
        RETURNING id INTO _inserted_event_id;

        -- Relate events with categories
        FOREACH _category_id IN ARRAY _categories
            LOOP
                INSERT INTO events.Event_Has_Category (event_id, category_id)
                VALUES (_inserted_event_id, _category_id);
            END LOOP;

        IF _event_sales_data IS NOT NULL THEN
            INSERT INTO events.Event_With_Sales (event_id, capacity, maximum_per_sale)
            VALUES (_inserted_event_id, _event_sales_data.capacity, _event_sales_data.capacity);
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN raise_exception THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Update events
CREATE FUNCTION events.update_event(
    _id events.Event.id%type,
    _name events.Event.name%type,
    _start_date events.Event.start_date%type,
    _end_date events.Event.end_date%type,
    _schedule events.Event.schedule%type,
    _description events.Event.description%type,
    _price events.Event.price%type,
    _image events.Event.image%type,
    _event_status events.Event.event_status%type,
    _event_published events.Event.event_published%type,
    _comments events.Event.comments%type,
    _organizer_id events.Event.organizer_id%type,
    _location_id events.Event.location_id%type,
    _categories INT[],
    _event_sales_data events.event_sales_data DEFAULT NULL
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters           TEXT;
    _procedure_id               INTEGER;
    _result                     TEXT;
    _valid_categories_count     INTEGER;
    _category_id                INTEGER;
    _formatted_event_sales_data TEXT;
    _event_has_sales            BOOLEAN;
BEGIN
    IF _event_sales_data IS NOT NULL THEN
        _formatted_event_sales_data := format(
                'Capacity: %s - Maximum Per Sale: %s',
                _event_sales_data.capacity,
                _event_sales_data.maximum_per_sale);
    END IF;

    _entry_parameters := format(
            'ID: %s | Name: %s | Start Date: %s | End Date: %s | Schedule: %s | Description: %s | Price: %s' ||
            ' | Image: %s | Event Status: %s | Event Published: %s | Comments: %s | Organizer ID: %s' ||
            ' | Location ID: %s | Categories: %s | Event Sales Data: %s',
            _id,
            _name,
            _start_date,
            _end_date,
            _schedule,
            _description,
            _price,
            _image,
            _event_status,
            _event_published,
            _comments,
            _organizer_id,
            _location_id,
            array_to_string(_categories::text[], ', '),
            _formatted_event_sales_data);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'update_event';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure update_event is not registered in the procedures table';
        END IF;

        -- Check that all categories exist
        SELECT COUNT(*)
        FROM events.Category
        WHERE id = ANY (_categories)
        INTO _valid_categories_count;

        IF _valid_categories_count < array_length(_categories, 1) THEN
            RAISE EXCEPTION 'Some categories do not exist';
        END IF;

        _event_has_sales := false;
        IF _event_sales_data IS NOT NULL THEN
            _event_has_sales := true;
        END IF;

        -- Create event
        UPDATE events.Event
        SET name            = _name,
            start_date      = _start_date,
            end_date        = _end_date,
            schedule        = _schedule,
            description     = _description,
            price           = _price,
            image           = _image,
            event_status    = _event_status,
            event_published = _event_published,
            comments        = _comments,
            event_has_sales = _event_has_sales,
            organizer_id    = _organizer_id,
            location_id     = _location_id
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Event "%" does not exist', _id;
        END IF;

        -- Delete all
        DELETE FROM events.Event_Has_Category WHERE event_id = _id;

        -- Relate events with categories
        FOREACH _category_id IN ARRAY _categories
            LOOP
                INSERT INTO events.Event_Has_Category (event_id, category_id)
                VALUES (_id, _category_id);
            END LOOP;

        -- Handle sales data
        IF _event_sales_data IS NOT NULL THEN
            IF EXISTS (SELECT 1 FROM events.Event_With_Sales WHERE event_id = _id) THEN
                UPDATE events.Event_With_Sales
                SET capacity         = _event_sales_data.capacity,
                    maximum_per_sale = _event_sales_data.maximum_per_sale
                WHERE event_id = _id;
            ELSE
                INSERT INTO events.Event_With_Sales (event_id, capacity, maximum_per_sale)
                VALUES (_id, _event_sales_data.capacity, _event_sales_data.maximum_per_sale);
            END IF;
        ELSE
            DELETE FROM events.Event_With_Sales WHERE event_id = _id;
        END IF;

        _result := 'OK';
    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Unable to remove event with sales with related transactions';
        WHEN raise_exception THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

-- Delete event
CREATE FUNCTION events.delete_event(
    _id events.Event.id%type
) RETURNS TEXT AS
$$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('ID: %s', _id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'delete_event';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure delete_event is not registered in the procedures table';
        END IF;

        DELETE
        FROM events.Event
        WHERE id = _id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Event "%" does not exist', _id;
        END IF;

    EXCEPTION
        WHEN foreign_key_violation THEN
            _result := 'ERROR: Event has related transactions';
        WHEN raise_exception THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;
