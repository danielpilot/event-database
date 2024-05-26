\c event_database;

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
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_event_statistics_on_rating_insert
    BEFORE INSERT
    ON events.rating
    FOR EACH ROW
EXECUTE PROCEDURE events.update_event_statistics_on_rating_insert();
