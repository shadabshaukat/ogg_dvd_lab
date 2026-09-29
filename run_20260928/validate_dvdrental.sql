-- Run on both source and target as postgres after the source writer is fenced
-- and Replicat has passed the barrier. psql -X -At -v ON_ERROR_STOP=1 -f validate_dvdrental.sql
SET TIME ZONE 'UTC';
SET DateStyle = 'ISO, YMD';
SET IntervalStyle = 'postgres';
SET extra_float_digits = 3;
SET bytea_output = 'hex';

SELECT 'table', table_name, row_count, fingerprint
FROM (
  SELECT 'actor' AS table_name, count(*) AS row_count, md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) AS fingerprint FROM dvdrental.actor t
  UNION ALL SELECT 'address', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.address t
  UNION ALL SELECT 'category', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.category t
  UNION ALL SELECT 'city', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.city t
  UNION ALL SELECT 'country', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.country t
  UNION ALL SELECT 'customer', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.customer t
  UNION ALL SELECT 'film', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.film t
  UNION ALL SELECT 'film_actor', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.film_actor t
  UNION ALL SELECT 'film_category', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.film_category t
  UNION ALL SELECT 'inventory', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.inventory t
  UNION ALL SELECT 'language', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.language t
  UNION ALL SELECT 'payment', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.payment t
  UNION ALL SELECT 'rental', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.rental t
  UNION ALL SELECT 'staff', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.staff t
  UNION ALL SELECT 'store', count(*), md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) FROM dvdrental.store t
) AS comparison
ORDER BY table_name;

SELECT 'sequence', table_name, max_id, sequence_last, is_called
FROM (
  SELECT 'actor' AS table_name, (SELECT max(actor_id) FROM dvdrental.actor) AS max_id, last_value AS sequence_last, is_called FROM dvdrental.actor_actor_id_seq
  UNION ALL SELECT 'address', (SELECT max(address_id) FROM dvdrental.address), last_value, is_called FROM dvdrental.address_address_id_seq
  UNION ALL SELECT 'category', (SELECT max(category_id) FROM dvdrental.category), last_value, is_called FROM dvdrental.category_category_id_seq
  UNION ALL SELECT 'city', (SELECT max(city_id) FROM dvdrental.city), last_value, is_called FROM dvdrental.city_city_id_seq
  UNION ALL SELECT 'country', (SELECT max(country_id) FROM dvdrental.country), last_value, is_called FROM dvdrental.country_country_id_seq
  UNION ALL SELECT 'customer', (SELECT max(customer_id) FROM dvdrental.customer), last_value, is_called FROM dvdrental.customer_customer_id_seq
  UNION ALL SELECT 'film', (SELECT max(film_id) FROM dvdrental.film), last_value, is_called FROM dvdrental.film_film_id_seq
  UNION ALL SELECT 'inventory', (SELECT max(inventory_id) FROM dvdrental.inventory), last_value, is_called FROM dvdrental.inventory_inventory_id_seq
  UNION ALL SELECT 'language', (SELECT max(language_id) FROM dvdrental.language), last_value, is_called FROM dvdrental.language_language_id_seq
  UNION ALL SELECT 'payment', (SELECT max(payment_id) FROM dvdrental.payment), last_value, is_called FROM dvdrental.payment_payment_id_seq
  UNION ALL SELECT 'rental', (SELECT max(rental_id) FROM dvdrental.rental), last_value, is_called FROM dvdrental.rental_rental_id_seq
  UNION ALL SELECT 'staff', (SELECT max(staff_id) FROM dvdrental.staff), last_value, is_called FROM dvdrental.staff_staff_id_seq
  UNION ALL SELECT 'store', (SELECT max(store_id) FROM dvdrental.store), last_value, is_called FROM dvdrental.store_store_id_seq
) AS sequence_check
ORDER BY table_name;
