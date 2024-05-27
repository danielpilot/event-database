\c event_database;

-- Create Top 10 most commented events view
CREATE VIEW statistics.Top10EventsWithMostComments AS
SELECT event_id, ratings_count
FROM statistics.event_statistics
ORDER BY ratings_count DESC
LIMIT 10;
