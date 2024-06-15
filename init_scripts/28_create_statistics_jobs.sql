\c event_database;

-- Create table update procedures
CREATE FUNCTION statistics.update_top_commented_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_commented_events;

    INSERT INTO statistics.top_commented_events
    SELECT es.event_id, ev.name
    FROM statistics.event_statistics es
    JOIN events.event ev ON es.event_id = ev.id
    ORDER BY es.total_rating DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_top_valued_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_valued_events;

    INSERT INTO statistics.top_valued_events
    SELECT es.event_id, ev.name
    FROM statistics.event_statistics es
    JOIN events.event ev ON es.event_id = ev.id
    ORDER BY es.average_rating DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_top_sold_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_sold_events;

    INSERT INTO statistics.top_sold_events
    SELECT ews.event_id, ev.name
    FROM events.event_with_sales ews
    JOIN events.event ev ON ews.event_id = ev.id
    ORDER BY ews.sales DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_top_locations_with_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_event_locations;

    INSERT INTO statistics.top_event_locations
    SELECT ls.location_id, l.name
    FROM statistics.location_statistics ls
    JOIN events.location l ON ls.location_id = l.id
    ORDER BY ls.events DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_top_cities_with_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_event_cities;

    INSERT INTO statistics.top_event_cities
    SELECT ls.location_id, c.name
    FROM statistics.location_statistics ls
    JOIN events.location l ON ls.location_id = l.id
    JOIN events.city c ON l.city_id = c.id
    ORDER BY ls.events DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION statistics.update_top_favorite_events() RETURNS VOID AS
$$
BEGIN
    DELETE FROM statistics.top_favorite_events;

    INSERT INTO statistics.top_favorite_events
    SELECT es.event_id, ev.name
    FROM statistics.event_statistics es
    JOIN events.event ev ON es.event_id = ev.id
    ORDER BY es.favorites DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Create statistics update jobs
SELECT cron.schedule('0 0 * * *', $$CALL statistics.update_top_commented_events()$$);
SELECT cron.schedule('0 1 * * *', $$CALL statistics.update_top_valued_events()$$);
SELECT cron.schedule('0 2 * * *', $$CALL statistics.update_top_sold_events()$$);
SELECT cron.schedule('0 3 * * *', $$CALL statistics.update_top_locations_with_events()$$);
SELECT cron.schedule('0 4 * * *', $$CALL statistics.update_top_cities_with_events()$$);
SELECT cron.schedule('0 5 * * *', $$CALL statistics.update_top_favorite_events()$$);
SELECT cron.schedule('0 6 * * *', $$CALL statistics.update_transaction_variation_last_month()$$);
