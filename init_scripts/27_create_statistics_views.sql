\c event_database;

-- Create Top 10 most commented events view
CREATE VIEW statistics.Top10EventsWithMostComments AS
SELECT event_id, ratings_count
FROM statistics.event_statistics
ORDER BY ratings_count DESC
LIMIT 10;

-- Create Top 10 best valued events view
CREATE VIEW statistics.Top10EventsWithBestPunctuation AS
SELECT event_id, average_rating, ratings_count
FROM statistics.event_statistics
ORDER BY average_rating DESC
LIMIT 10;
