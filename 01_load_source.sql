-- 01_load_source.sql
-- Appends generated fixture data to the SYD source database only.
-- Prerequisite: run 00_create_schema.sql once on a fresh database.
-- Usage: psql -X "$SOURCE_DSN" -v ON_ERROR_STOP=1 -v rows=100000 -f 01_load_source.sql
\set ON_ERROR_STOP on

-- Validate the psql variable before it is cast or used in SQL.  :'rows'
-- quotes the value as a SQL literal and avoids raw variable substitution.
\if :{?rows}
\else
  DO $validation$
  BEGIN
    RAISE EXCEPTION 'Required: -v rows=<integer from 1 to 1000000>.';
  END
  $validation$;
\endif

SELECT :'rows' ~ '^(1000000|[1-9][0-9]{0,5})$' AS rows_is_valid
\gset
\if :rows_is_valid
\else
  DO $validation$
  BEGIN
    RAISE EXCEPTION 'Invalid rows: expected an integer from 1 to 1000000.';
  END
  $validation$;
\endif

SELECT to_regprocedure('dvd_lab.generate_data(integer)') IS NOT NULL AS schema_is_ready
\gset
\if :schema_is_ready
\else
  DO $validation$
  BEGIN
    RAISE EXCEPTION 'Missing dvd_lab.generate_data(integer); run 00_create_schema.sql first.';
  END
  $validation$;
\endif

\echo 'Appending' :rows 'rentals and payments to the SYD source...'
BEGIN;
SET LOCAL TIME ZONE 'UTC';
CALL dvd_lab.generate_data(:'rows'::integer);
COMMIT;
\echo 'Source data load completed.'

