\set ON_ERROR_STOP on
BEGIN;
ALTER TABLE dvdrental.film ALTER COLUMN release_year TYPE integer USING release_year::integer;
ALTER TABLE dvdrental.film ADD CONSTRAINT film_release_year_range CHECK (release_year BETWEEN 1901 AND 2155);
DROP DOMAIN dvdrental.year;
CREATE INDEX film_original_language_idx ON dvdrental.film (original_language_id);
CREATE INDEX inventory_store_idx ON dvdrental.inventory (store_id);
CREATE INDEX staff_address_idx ON dvdrental.staff (address_id);
CREATE INDEX store_address_idx ON dvdrental.store (address_id);
CREATE SCHEMA IF NOT EXISTS ggadmin AUTHORIZATION postgres;
COMMIT;
