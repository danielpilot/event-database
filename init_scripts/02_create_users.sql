CREATE USER event_user WITH PASSWORD 'event_user_pass';
CREATE USER statistics_user WITH PASSWORD 'statistics_user_pass';

ALTER USER event_user SET default_tablespace = 'operational_tablespace';
ALTER USER statistics_user SET default_tablespace = 'warehouse_tablespace';
