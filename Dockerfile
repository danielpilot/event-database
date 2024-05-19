FROM postgres:14

# Install pgTAP
RUN apt-get update && apt-get -y install postgresql-14-pgtap

# Create different locations for tablespaces
RUN mkdir -p /var/lib/pg_tablespaces/operational_tablespace
RUN mkdir -p /var/lib/pg_tablespaces/warehouse_tablespace

RUN chown -R postgres:postgres /var/lib/pg_tablespaces

# Copy the test files
COPY ./tests/*.sql /app/tests/
