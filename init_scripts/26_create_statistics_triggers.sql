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

CREATE FUNCTION events.increase_statistics_location(
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

    PERFORM events.increase_statistics_city((SELECT city_id::integer FROM events.location WHERE id = _location_id));
END;
$$ language plpgsql;

CREATE FUNCTION events.decrease_statistics_location(
    _location_id INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT location_id FROM statistics.location_statistics WHERE location_id = _location_id) THEN
        UPDATE statistics.location_statistics
        SET events = events - 1
        WHERE location_id = _location_id;
    END IF;

    PERFORM events.decrease_statistics_city((SELECT city_id::integer FROM events.location WHERE id = _location_id));
END;

$$ language plpgsql;

CREATE FUNCTION events.increase_statistics_city(
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

CREATE FUNCTION events.decrease_statistics_city(
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
    IF NEW.event_id = OLD.event_id THEN
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

-- Create location statistics on event create
CREATE FUNCTION events.update_location_statistics_on_event_insert() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT (NEW.event_published AND NEW.event_status) THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistics_location(NEW.location_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_insert
    AFTER INSERT
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_location_statistics_on_event_insert();

-- Update location statistics on event update
CREATE FUNCTION events.update_location_statistics_on_event_update() RETURNS TRIGGER AS
$$
BEGIN
    IF (NEW.event_published AND NEW.event_status) AND NOT (OLD.event_published AND NEW.event_status) THEN
        PERFORM events.increase_statistics_location(NEW.location_id);
        RETURN NEW;
    END IF;

    IF (OLD.event_published AND OLD.event_status) AND NOT (NEW.event_published AND NEW.event_status) THEN
        PERFORM events.decrease_statistics_location(OLD.location_id);
        RETURN NEW;
    END IF;

    IF NEW.location_id = OLD.location_id THEN
        RETURN NEW;
    END IF;

    PERFORM events.increase_statistics_location(NEW.location_id);
    PERFORM events.decrease_statistics_location(OLD.location_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_update
    AFTER UPDATE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_location_statistics_on_event_update();

-- Update location statistics on event delete
CREATE FUNCTION events.update_location_statistics_on_event_delete() RETURNS TRIGGER AS
$$
BEGIN
    IF NOT (OLD.event_published AND OLD.event_status) THEN
        RETURN OLD;
    END IF;

    PERFORM events.decrease_statistics_location(OLD.location_id);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_event_delete
    AFTER DELETE
    ON events.event
    FOR EACH ROW
EXECUTE PROCEDURE events.update_location_statistics_on_event_delete();
