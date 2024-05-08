FROM postgres:latest

RUN mkdir -p /var/lib/pg_tablespaces/operational_tablespace
RUN mkdir -p /var/lib/pg_tablespaces/warehouse_tablespace

RUN chown -R postgres:postgres /var/lib/pg_tablespaces