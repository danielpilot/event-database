FROM postgres:14

# Install pgTAP
RUN apt-get update && apt-get -y install postgresql-14-pgtap postgresql-14-cron

# Create different locations for tablespaces
RUN mkdir -p /var/lib/pg_tablespaces/operational_tablespace
RUN mkdir -p /var/lib/pg_tablespaces/warehouse_tablespace

RUN chown -R postgres:postgres /var/lib/pg_tablespaces

# Add pg_cron data to postgresql config
RUN echo "shared_preload_libraries='pg_cron'" >> /usr/share/postgresql/postgresql.conf.sample
RUN echo "cron.database_name='event_database'" >> /usr/share/postgresql/postgresql.conf.sample

# Copy the test files
COPY ./tests/*.sql /app/tests/
