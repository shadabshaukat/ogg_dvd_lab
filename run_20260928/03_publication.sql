\set ON_ERROR_STOP on
CREATE PUBLICATION ogg_migration_pub FOR TABLE
  dvdrental.actor,
  dvdrental.address,
  dvdrental.category,
  dvdrental.city,
  dvdrental.country,
  dvdrental.customer,
  dvdrental.film,
  dvdrental.film_actor,
  dvdrental.film_category,
  dvdrental.inventory,
  dvdrental.language,
  dvdrental.payment,
  dvdrental.rental,
  dvdrental.staff,
  dvdrental.store
WITH (publish = 'insert, update, delete, truncate');
SELECT pubname, pubinsert, pubupdate, pubdelete, pubtruncate FROM pg_publication WHERE pubname='ogg_migration_pub';
SELECT schemaname,tablename FROM pg_publication_tables WHERE pubname='ogg_migration_pub' ORDER BY 1,2;
