\c event_database;

-- Auxiliary statistics functions
CREATE FUNCTION events.increase_statistic_rankings(
    _event_id INTEGER,
    _punctuation INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count + 1,
            average_rating = (total_rating + _punctuation::float) / (ratings_count + 1),
            total_rating   = total_rating + _punctuation
        WHERE event_id = _event_id;
    ELSE
        INSERT INTO statistics.event_statistics (event_id,
                                                 ratings_count,
                                                 average_rating,
                                                 total_rating,
                                                 sales,
                                                 occupancy)
        VALUES (_event_id, 1, _punctuation, _punctuation, 0, 0);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION events.decrease_statistic_rankings(
    _event_id INTEGER,
    _punctuation INTEGER
) RETURNS VOID AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = _event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count - 1,
            average_rating = (total_rating - _punctuation::float) / (ratings_count - 1),
            total_rating   = total_rating - _punctuation
        WHERE event_id = _event_id;
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

    PERFORM events.increase_statistic_rankings(NEW.event_id, NEW.punctuation);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_insert
    BEFORE INSERT
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
        PERFORM events.increase_statistic_rankings(NEW.event_id, NEW.punctuation);
    END IF;

    -- If the event is not published anymore, we delete the rating
    IF OLD.published AND NOT NEW.published THEN
        PERFORM events.decrease_statistic_rankings(OLD.event_id, OLD.punctuation);
    END IF;

    -- If the event was published and it's still published, we update the rating
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = NEW.event_id) THEN
        UPDATE statistics.event_statistics
        SET average_rating = (total_rating + NEW.punctuation::float - OLD.punctuation::float) / ratings_count,
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

    PERFORM events.decrease_statistic_rankings(OLD.event_id, OLD.punctuation);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_delete
    AFTER DELETE
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_delete();
