\c events_database;

-- Create category
CREATE FUNCTION events.create_category(
    _name events.Category.name%type,
    _parent_category_id events.Category.id%type
) RETURNS TEXT AS $$
DECLARE
    _entry_parameters TEXT;
    _procedure_id     INTEGER;
    _result           TEXT;
BEGIN
    _entry_parameters := format('Name: %s | Parent Category ID: %s', _name, _parent_category_id);

    BEGIN
        SELECT id INTO _procedure_id FROM logs.Procedures WHERE name = 'create_category';

        IF _procedure_id IS NULL THEN
            RAISE EXCEPTION 'Procedure create_category is not registered in the procedures table';
        END IF;

        IF _parent_category_id IS NOT NULL THEN
            IF NOT EXISTS (SELECT 1 FROM events.category WHERE id = _parent_category_id) THEN
                RAISE EXCEPTION 'Parent with ID "%" does not exist', _parent_category_id;
            END IF;
        END IF;

        INSERT INTO events.Category (name, parent_category)
        VALUES (_name, _parent_category_id);

        _result := 'OK';
    EXCEPTION
        WHEN unique_violation THEN
            _result := format('ERROR: Category with name "%s" already exists under the specified parent', _name);
        WHEN foreign_key_violation THEN
            _result := format('ERROR: Category parent with ID "%s" not found', _parent_category_id);
        WHEN raise_exception THEN
            _result := format('ERROR: %s', SQLERRM);
    END;

    INSERT INTO logs.Log (date, db_user, procedure_id, entry_parameters, result)
    VALUES (NOW(), CURRENT_USER, _procedure_id, _entry_parameters, _result);

    RETURN _result;
END
$$ LANGUAGE plpgsql;

