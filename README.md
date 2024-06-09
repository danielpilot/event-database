# Event Database
This project is developed as a Bachelor's Thesis for the Computer Engineering degree at the [Universitat Oberta de Catalunya](https://www.uoc.edu/).

## Project description
The purpose of the project is to create a database that stores events information.

This database is designed to be used by applications that track event and location data, and supports the implementation of a user system with ticketing functionality.

## Used technologies
* **Database management system**: PostgreSQL 14. 
* **Programming languages**: SQL, PL/pgSQL
* **Database testing**: pgTAP
* **Containerization**: Docker

## Execution
1. Run the docker container

```bash
docker-compose up -d
```

## Testing
Automatic testing has been implemented using pgTAP. You can run all the tests included in the project inside the container:

```bash
docker exec -it event_database_db_1 bash
pg_prove -U postgres /app/tests/*.sql --verbose
```
