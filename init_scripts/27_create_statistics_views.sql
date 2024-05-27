\c event_database;

-- Create Top 10 most commented events view
CREATE VIEW statistics.Top10EventsWithMostComments AS
SELECT event_id, comments
FROM statistics.event_statistics
ORDER BY comments DESC
LIMIT 10;
