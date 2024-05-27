\c event_database;

-- Update event statistics on rating insert
CREATE FUNCTION events.update_event_statistics_on_rating_insert() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = NEW.event_id) THEN
        UPDATE statistics.event_statistics
        SET comments = comments + 1
        WHERE event_id = NEW.event_id;
    ELSE
        INSERT INTO statistics.event_statistics (event_id, comments, average_rating, sales, occupancy)
        VALUES (NEW.event_id, 1, 0, 0, 0);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_insert
    BEFORE INSERT
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_insert();

-- Update event statistics on rating delete
CREATE FUNCTION events.update_event_statistics_on_rating_delete() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT event_id FROM statistics.event_statistics WHERE rating.event_id = OLD.event_id) THEN
        UPDATE statistics.event_statistics
        SET comments = comments - 1
        WHERE event_id = NEW.event_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_event_statistics_on_rating_insert
    AFTER DELETE
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_delete();
