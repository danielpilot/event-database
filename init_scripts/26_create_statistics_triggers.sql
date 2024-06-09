\c event_database;

-- Auxiliary statistics functions
CREATE FUNCTION events.increase_statistic_ratings(
    _event_id INTEGER,
    _punctuation INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count + 1,
            average_rating = (total_rating + _punctuation::real) / (ratings_count + 1),
            total_rating   = total_rating + _punctuation
        WHERE event_id = _event_id;
    ELSE
        INSERT INTO statistics.event_statistics (event_id,
                                                 ratings_count,
                                                 average_rating,
                                                 total_rating)
        VALUES (_event_id, 1, _punctuation::real, _punctuation);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_ratings(
    _event_id INTEGER,
    _punctuation INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count - 1,
            average_rating = (total_rating - _punctuation) / (ratings_count - 1),
            total_rating   = total_rating - _punctuation
        WHERE event_id = _event_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.increase_statistic_favorites(
    _event_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET favorites = favorites + 1
        WHERE event_id = _event_id;
    ELSE
        INSERT INTO statistics.event_statistics (event_id,
                                                 favorites)
        VALUES (_event_id, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_ratings(
    _event_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET favorites = favorites - 1
        WHERE event_id = _event_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.increase_statistic_location(
    _location_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT location_id FROM statistics.location_statistics WHERE location_id = _location_id) THEN
        UPDATE statistics.location_statistics
        SET events = events + 1
        WHERE location_id = _location_id;
    ELSE
        INSERT INTO statistics.location_statistics (location_id,
                                                    events)
        VALUES (_location_id, 1);
    END IF;

    PERFORM events.increase_statistic_city((SELECT city_id::integer FROM events.location WHERE id = _location_id));
END;
$$ language plpgsql;

CREATE FUNCTION events.decrease_statistic_location(
    _location_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT location_id FROM statistics.location_statistics WHERE location_id = _location_id) THEN
        UPDATE statistics.location_statistics
        SET events = events - 1
        WHERE location_id = _location_id;
    END IF;

    PERFORM events.decrease_statistic_city((SELECT city_id::integer FROM events.location WHERE id = _location_id));
END;

$$ language plpgsql;

CREATE FUNCTION events.increase_statistic_city(
    _city_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT city_id FROM statistics.city_statistics WHERE city_id = _city_id) THEN
        UPDATE statistics.city_statistics
        SET events = events + 1
        WHERE city_id = _city_id;
    ELSE
        INSERT INTO statistics.city_statistics (city_id,
                                                events)
        VALUES (_city_id, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_city(
    _city_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT city_id FROM statistics.city_statistics WHERE city_id = _city_id) THEN
        UPDATE statistics.city_statistics
        SET events = events - 1
        WHERE city_id = _city_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_average_transactions_per_user() RETURNS VOID AS
$$
DECLARE
    _non_admin_users    INTEGER;
    _total_transactions INTEGER;
BEGIN
    SELECT value::integer INTO _non_admin_users FROM statistics.system_counters WHERE name = 'non_admin_users';
    SELECT value::integer INTO _total_transactions FROM statistics.system_counters WHERE name = 'total_transactions';

    IF _non_admin_users = 0 THEN
        UPDATE statistics.percentage_indicators
        SET value = 0.0
        WHERE indicator = 2;
        RETURN;
    END IF;

    UPDATE statistics.percentage_indicators
    SET value = ROUND((_total_transactions::real / _non_admin_users::real)::numeric, 2)
    WHERE indicator = 2;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.increase_statistic_event_counter() RETURNS VOID AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value + 1
    WHERE name = 'total_events';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_event_counter() RETURNS VOID AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value - 1
    WHERE name = 'total_events';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.increase_statistic_event_sales_counter() RETURNS VOID AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value + 1
    WHERE name = 'total_payed_events';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_event_sales_counter() RETURNS VOID AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value - 1
    WHERE name = 'total_payed_events';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.update_average_price(
    _event_price REAL,
    _is_increment BOOLEAN
) RETURNS VOID AS
$$
DECLARE
    _total_price        INTEGER;
    _total_payed_events INTEGER;
BEGIN
    IF _is_increment THEN
        UPDATE statistics.percentage_indicators
        SET value = value + _event_price
        WHERE indicator = 4;
    ELSE
        UPDATE statistics.percentage_indicators
        SET value = value - _event_price
        WHERE indicator = 4;
    END IF;

    SELECT value INTO _total_payed_events FROM statistics.system_counters WHERE name = 'total_payed_events';

    IF (_total_payed_events = 0) THEN
        UPDATE statistics.percentage_indicators
        SET value = 0.0
        WHERE indicator = 1;

        RETURN;
    END IF;

    SELECT value INTO _total_price FROM statistics.percentage_indicators WHERE indicator = 4;

    UPDATE statistics.percentage_indicators
    SET value = ROUND((_total_price::real / _total_payed_events::real)::numeric, 2)
    WHERE indicator = 1;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.update_payed_events_percentage() RETURNS VOID AS
$$
DECLARE
    _total_events       INTEGER;
    _total_payed_events INTEGER;
BEGIN
    SELECT value::integer INTO _total_events FROM statistics.system_counters WHERE name = 'total_events';
    SELECT value::integer INTO _total_payed_events FROM statistics.system_counters WHERE name = 'total_payed_events';

    IF _total_events = 0 THEN
        UPDATE statistics.percentage_indicators
        SET value = 0.0
        WHERE indicator = 3;
        RETURN;
    END IF;

    UPDATE statistics.percentage_indicators
    SET value = ROUND(((_total_payed_events::real / _total_events::real) * 100)::numeric, 2)
    WHERE indicator = 3;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_transaction_statistics(
    _transaction_month INTEGER,
    _transaction_year INTEGER,
    _is_increment BOOLEAN
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT *
               FROM statistics.transaction_statistics
               WHERE month = _transaction_month
                 AND year = _transaction_year) THEN
        IF _is_increment THEN
            UPDATE statistics.transaction_statistics
            SET transactions = transactions + 1
            WHERE month = _transaction_month
              AND year = _transaction_year;
        ELSE
            UPDATE statistics.transaction_statistics
            SET transactions = transactions - 1
            WHERE month = _transaction_month
              AND year = _transaction_year;
        END IF;
    ELSE
        IF _is_increment THEN
            INSERT INTO statistics.transaction_statistics (month, year, transactions)
            VALUES (_transaction_month, _transaction_year, 1);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_transaction_variation_last_month() RETURNS VOID AS
$$
DECLARE
    _last_month_transactions    INTEGER;
    _current_month_transactions INTEGER;
    _variation                  FLOAT;
BEGIN
    SELECT transactions
    INTO _current_month_transactions
    FROM statistics.transaction_statistics
    WHERE month = EXTRACT(MONTH FROM CURRENT_DATE)
      AND year = EXTRACT(YEAR FROM CURRENT_DATE);

    IF NOT FOUND THEN
        _current_month_transactions := 0;
    END IF;

    SELECT transactions
    INTO _last_month_transactions
    FROM statistics.transaction_statistics
    WHERE month = EXTRACT(MONTH FROM NOW() - INTERVAL '1 month')
      AND year = EXTRACT(YEAR FROM NOW() - INTERVAL '1 month');

    IF NOT FOUND THEN
        _last_month_transactions := 0;
    END IF;

    IF _last_month_transactions = 0 THEN
        _variation := 100;
    ELSE
        _variation := ((_current_month_transactions - _last_month_transactions) / _last_month_transactions) * 100;
    END IF;

    UPDATE statistics.percentage_indicators
    SET value = _variation
    WHERE indicator = 5;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_event_with_sales_occupation(_event_with_sales_id INTEGER) RETURNS VOID AS
$$
DECLARE
    _event_id                INTEGER;
    _capacity                SMALLINT;
    _sales                   SMALLINT;
    _occupation              FLOAT;
    _previous_occupation     FLOAT;
    _full_events_number      INTEGER;
    _total_payed_events      INTEGER;
    _total_events_occupation FLOAT;
BEGIN
    SELECT event_id, capacity, sales
    INTO _event_id, _capacity, _sales
    FROM events.event_with_sales
    WHERE id = _event_with_sales_id;

    IF _capacity = 0 THEN
        _occupation = 0;
    ELSE
        _occupation = ROUND(((_sales::real / _capacity::real) * 100)::numeric, 2);
    END IF;

    SELECT occupation INTO _previous_occupation FROM statistics.event_statistics WHERE event_id = _event_id;

    IF NOT FOUND THEN
        INSERT INTO statistics.event_statistics (event_id, occupation)
        VALUES (_event_id, _occupation);
    ELSE
        UPDATE statistics.event_statistics
        SET occupation = _occupation
        WHERE event_id = _event_id;
    END IF;

    IF _occupation = 100 AND NOT _previous_occupation = 100 THEN
        UPDATE statistics.integer_indicators
        SET value = value + 1
        WHERE indicator = 1;
    END IF;

    IF _previous_occupation = 100 AND NOT _occupation = 100 THEN
        UPDATE statistics.integer_indicators
        SET value = value - 1
        WHERE indicator = 1;
    END IF;

    IF _previous_occupation IS NOT NULL THEN
        UPDATE statistics.percentage_indicators
        SET value = value - _previous_occupation + _occupation
        WHERE indicator = 6;
    ELSE
        UPDATE statistics.percentage_indicators
        SET value = value + _occupation
        WHERE indicator = 6;
    END IF;

    SELECT value INTO _total_payed_events FROM statistics.system_counters WHERE name = 'total_payed_events';
    SELECT value INTO _total_events_occupation FROM statistics.percentage_indicators WHERE indicator = 6;

    UPDATE statistics.percentage_indicators
    SET VALUE = ROUND((_total_events_occupation::real / _total_payed_events::real)::numeric, 2)
    WHERE indicator = 7;

    SELECT value INTO _full_events_number FROM statistics.integer_indicators WHERE indicator = 1;

    UPDATE statistics.percentage_indicators
    SET value = ROUND(((_full_events_number::real / _total_payed_events::real) * 100)::numeric, 2)
    WHERE indicator = 8;
END;
$$ LANGUAGE plpgsql;

-- Update event statistics on rating insert
CREATE FUNCTION events.update_event_statistics_on_rating_insert() RETURNS TRIGGER AS
$$
BEGIN
    -- We only modify the statistics if the event is published
    IF NOT NEW.published THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistic_ratings(NEW.event_id, NEW.punctuation);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_insert
    AFTER INSERT
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_insert();

-- Update event statistics on rating update
CREATE FUNCTION events.update_event_statistics_on_rating_update() RETURNS TRIGGER AS
$$
BEGIN
    -- We only modify the statistics if the event is published
    IF NOT OLD.published AND NOT NEW.published THEN
        RETURN NEW;
    END IF;

    -- If the event was not published and now it is, we insert the rating
    IF NOT OLD.published AND NEW.published THEN
        PERFORM events.increase_statistic_ratings(NEW.event_id, NEW.punctuation);
        RETURN NEW;
    END IF;

    -- If the event is not published anymore, we delete the rating
    IF OLD.published AND NOT NEW.published THEN
        PERFORM events.decrease_statistic_ratings(OLD.event_id, OLD.punctuation);
        RETURN NEW;
    END IF;

    -- If the event was published and it's still published, we update the rating
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE event_id = NEW.event_id) THEN
        UPDATE statistics.event_statistics
        SET average_rating = (total_rating + NEW.punctuation - OLD.punctuation) / ratings_count,
            total_rating   = total_rating + NEW.punctuation - OLD.punctuation
        WHERE event_id = NEW.event_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_update
    AFTER UPDATE
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_update();

-- Update event statistics on rating delete
CREATE FUNCTION events.update_event_statistics_on_rating_delete() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT OLD.published THEN
        RETURN OLD;
    END IF;

    PERFORM events.decrease_statistic_ratings(OLD.event_id, OLD.punctuation);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_delete
    AFTER DELETE
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_delete();

-- Update event statistics on favorite insert
CREATE FUNCTION events.update_event_statistics_on_favorite_insert() RETURNS TRIGGER AS
$$
BEGIN
    PERFORM events.increase_statistic_favorites(NEW.event_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_favorite_insert
    AFTER INSERT
    ON events.event_favorite
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_favorite_insert();

-- Update event statistics on favorite update
CREATE FUNCTION events.update_event_statistics_on_favorite_update() RETURNS TRIGGER AS
$$
BEGIN
    IF COALESCE(NEW.event_id, OLD.event_id) = OLD.event_id THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistic_favorites(NEW.event_id);
    PERFORM events.decrease_statistic_ratings(OLD.event_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_favorite_update
    AFTER UPDATE
    ON events.event_favorite
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_favorite_update();

-- Delete event statistics on favorite delete
CREATE FUNCTION events.update_event_statistics_on_favorite_delete() RETURNS TRIGGER AS
$$
BEGIN
    PERFORM events.decrease_statistic_ratings(OLD.event_id);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_favorite_delete
    AFTER DELETE
    ON events.event_favorite
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_favorite_delete();

-- Update event statistics on event create
CREATE FUNCTION events.update_event_statistics_on_event_insert() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT (NEW.event_published AND NEW.event_status) THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistic_location(NEW.location_id);
    PERFORM events.increase_statistic_event_counter();

    IF NEW.event_has_sales THEN
        PERFORM events.increase_statistic_event_sales_counter();
        PERFORM events.update_average_price(NEW.price, TRUE);
    END IF;

    PERFORM events.update_payed_events_percentage();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_insert
    AFTER INSERT
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_event_insert();

-- Update event statistics on event update
CREATE FUNCTION events.update_event_statistics_on_event_update() RETURNS TRIGGER AS
$$
BEGIN
    IF ((COALESCE(NEW.event_published, OLD.event_published) AND COALESCE(NEW.event_status, OLD.event_status))
        AND NOT (OLD.event_published AND OLD.event_status))
    THEN
        PERFORM events.increase_statistic_location(NEW.location_id);
        PERFORM events.increase_statistic_event_counter();

        IF COALESCE(NEW.event_has_sales, OLD.event_has_sales) THEN
            PERFORM events.increase_statistic_event_sales_counter();
            PERFORM events.update_average_price(NEW.price, TRUE);
        END IF;

        PERFORM events.update_payed_events_percentage();

        RETURN NEW;
    END IF;

    IF ((OLD.event_published AND OLD.event_status)
        AND NOT (COALESCE(NEW.event_published, OLD.event_published) AND COALESCE(NEW.event_status, OLD.event_status)))
    THEN
        PERFORM events.decrease_statistic_location(OLD.location_id);
        PERFORM events.decrease_statistic_event_counter();

        IF OLD.event_has_sales THEN
            PERFORM events.decrease_statistic_event_sales_counter();
            PERFORM events.update_average_price(OLD.price, FALSE);
        END IF;

        PERFORM events.update_payed_events_percentage();

        RETURN NEW;
    END IF;

    IF (NOT (COALESCE(NEW.event_published, OLD.event_published) AND COALESCE(NEW.event_status, OLD.event_status)))
    THEN
        RETURN NEW;
    END IF;

    IF (OLD.event_has_sales AND COALESCE(NEW.event_has_sales, OLD.event_has_sales)) THEN
        PERFORM events.update_average_price(NEW.price - OLD.price, TRUE);
    END IF;

    IF (OLD.event_has_sales AND NOT COALESCE(NEW.event_has_sales, OLD.event_has_sales)) THEN
        PERFORM events.decrease_statistic_event_sales_counter();
        PERFORM events.update_average_price(OLD.price, FALSE);
    END IF;

    IF (NOT OLD.event_has_sales AND NEW.event_has_sales) THEN
        PERFORM events.increase_statistic_event_sales_counter();
        PERFORM events.update_average_price(NEW.price, TRUE);
    END IF;

    IF NEW.location_id = OLD.location_id THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistic_location(NEW.location_id);
    PERFORM events.decrease_statistic_location(OLD.location_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_update
    AFTER UPDATE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_event_update();

-- Update location statistics on event delete
CREATE FUNCTION events.update_location_statistics_on_event_delete() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT (OLD.event_published AND OLD.event_status) THEN
        RETURN OLD;
    END IF;

    PERFORM events.decrease_statistic_location(OLD.location_id);
    PERFORM events.decrease_statistic_event_counter();

    IF OLD.event_has_sales THEN
        PERFORM events.decrease_statistic_event_sales_counter();
        PERFORM events.update_average_price(OLD.price, FALSE);
    END IF;

    PERFORM events.update_payed_events_percentage();

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_delete
    AFTER DELETE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_location_statistics_on_event_delete();

-- Update user statistics on user insert
CREATE FUNCTION events.update_user_statistics_on_user_insert() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.roles LIKE '%admin%' THEN
        RETURN NEW;
    END IF;

    UPDATE statistics.system_counters
    SET value = value + 1
    WHERE name = 'non_admin_users';

    PERFORM statistics.update_average_transactions_per_user();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_statistics_on_user_insert
    AFTER INSERT
    ON events.User
    FOR EACH ROW
EXECUTE PROCEDURE events.update_user_statistics_on_user_insert();

-- Update user statistics on user update
CREATE FUNCTION events.update_user_statistics_on_user_update() RETURNS TRIGGER AS
$$
BEGIN
    IF OLD.roles NOT LIKE '%admin%' AND NEW.roles LIKE '%admin%' THEN
        UPDATE statistics.system_counters
        SET value = value - 1
        WHERE name = 'non_admin_users';
    END IF;

    IF OLD.roles LIKE '%admin%' AND NEW.roles NOT LIKE '%admin%' THEN
        UPDATE statistics.system_counters
        SET value = value + 1
        WHERE name = 'non_admin_users';
    END IF;

    PERFORM statistics.update_average_transactions_per_user();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_statistics_on_user_update
    AFTER UPDATE
    ON events.User
    FOR EACH ROW
EXECUTE PROCEDURE events.update_user_statistics_on_user_update();

-- Update user statistics on user delete
CREATE FUNCTION events.update_user_statistics_on_user_delete() RETURNS TRIGGER AS
$$
BEGIN
    IF OLD.roles NOT LIKE '%admin%' THEN
        UPDATE statistics.system_counters
        SET value = value - 1
        WHERE name = 'non_admin_users';
    END IF;

    PERFORM statistics.update_average_transactions_per_user();

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_statistics_on_user_delete
    AFTER DELETE
    ON events.User
    FOR EACH ROW
EXECUTE PROCEDURE events.update_user_statistics_on_user_delete();

-- Update transaction statistics on transaction insert
CREATE FUNCTION events.update_transaction_statistics_on_transaction_insert() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value + 1
    WHERE name = 'total_transactions';

    PERFORM statistics.update_average_transactions_per_user();

    PERFORM statistics.update_transaction_statistics(
            EXTRACT(MONTH FROM NEW.date)::integer,
            EXTRACT(YEAR FROM NEW.date)::integer,
            TRUE
            );
    PERFORM statistics.update_transaction_variation_last_month();

    PERFORM statistics.update_event_with_sales_occupation(NEW.event_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_transaction_statistics_on_transaction_insert
    AFTER INSERT
    ON events.Transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_transaction_statistics_on_transaction_insert();

-- Update transaction statistics on transaction update
CREATE FUNCTION events.update_transaction_statistics_on_transaction_update() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT (OLD.date = NEW.date) THEN
        PERFORM statistics.update_transaction_statistics(
                EXTRACT(MONTH FROM NEW.date)::integer,
                EXTRACT(YEAR FROM NEW.date)::integer,
                TRUE
                );

        PERFORM statistics.update_transaction_statistics(
                EXTRACT(MONTH FROM OLD.date)::integer,
                EXTRACT(YEAR FROM OLD.date)::integer,
                FALSE
                );

        PERFORM statistics.update_transaction_variation_last_month();
    END IF;

    PERFORM statistics.update_event_with_sales_occupation(NEW.event_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_transaction_statistics_on_transaction_update
    AFTER UPDATE
    ON events.Transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_transaction_statistics_on_transaction_update();

-- Update transaction statistics on transaction delete
CREATE FUNCTION events.update_transaction_statistics_on_transaction_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE statistics.system_counters
    SET value = value - 1
    WHERE name = 'total_transactions';

    PERFORM statistics.update_average_transactions_per_user();

    PERFORM statistics.update_transaction_statistics(
            EXTRACT(MONTH FROM OLD.date)::integer,
            EXTRACT(YEAR FROM OLD.date)::integer,
            FALSE
            );
    PERFORM statistics.update_transaction_variation_last_month();

    PERFORM statistics.update_event_with_sales_occupation(OLD.event_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_transaction_statistics_on_transaction_delete
    AFTER DELETE
    ON events.Transaction
    FOR EACH ROW
EXECUTE PROCEDURE events.update_transaction_statistics_on_transaction_delete();

-- Update occupation statistics on event with sales update
CREATE FUNCTION events.update_occupation_statistics_on_event_with_sales_update() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.capacity IS NOT NULL THEN
        PERFORM statistics.update_event_with_sales_occupation(NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_occupation_statistics_on_event_with_sales_update
    AFTER UPDATE
    ON events.event_with_sales
    FOR EACH ROW
EXECUTE PROCEDURE events.update_occupation_statistics_on_event_with_sales_update();
