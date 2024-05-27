\c event_database;

-- Update event statistics on rating insert
CREATE FUNCTION events.update_event_statistics_on_rating_insert() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = NEW.event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count + 1,
            average_rating = (total_rating + NEW.punctuation::float) / (ratings_count + 1),
            total_rating   = total_rating + NEW.punctuation
        WHERE event_id = NEW.event_id;
    ELSE
        INSERT INTO statistics.event_statistics (event_id,
                                                 ratings_count,
                                                 average_rating,
                                                 total_rating,
                                                 sales,
                                                 occupancy)
        VALUES (NEW.event_id, 1, NEW.punctuation, NEW.punctuation, 0, 0);
    END IF;

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
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = OLD.event_id) THEN
        UPDATE statistics.event_statistics
        SET ratings_count  = ratings_count - 1,
            average_rating = (total_rating - OLD.punctuation::float) / (ratings_count - 1),
            total_rating   = total_rating - OLD.punctuation
        WHERE event_id = NEW.event_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_delete
    AFTER DELETE
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_delete();
