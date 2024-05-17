FROM postgres:14

RUN apt-get update && apt-get -y install postgresql-14-pgtap

RUN mkdir -p /var/lib/pg_tablespaces/operational_tablespace
RUN mkdir -p /var/lib/pg_tablespaces/warehouse_tablespace

RUN chown -R postgres:postgres /var/lib/pg_tablespaces
