-- 00_create_schema.sql
-- Creates the complete DVD rental schema and source-only generator procedure.
-- Fresh database only. Run on SYD, MEL, and SGP; this file loads no rows.
-- Usage: psql -X "$DB_DSN" -v ON_ERROR_STOP=1 -f 00_create_schema.sql
\set ON_ERROR_STOP on

-- Fresh database only. Deliberately fails if dvdrental already exists.
-- Original lab implementation of the 15-table DVD rental model, not the
-- canonical sample dump. All surrogate keys use bigint; temporal columns use timestamptz.
BEGIN;
CREATE SCHEMA dvdrental;
CREATE SCHEMA dvd_lab;
SET LOCAL search_path = dvdrental, pg_catalog;
CREATE TYPE mpaa_rating AS ENUM ('G','PG','PG-13','R','NC-17');
CREATE DOMAIN year AS integer CHECK (VALUE BETWEEN 1901 AND 2155);

CREATE TABLE country (
 country_id bigserial PRIMARY KEY, country varchar(50) NOT NULL UNIQUE,
 last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE city (
 city_id bigserial PRIMARY KEY, city varchar(50) NOT NULL,
 country_id bigint NOT NULL REFERENCES country,
 last_update timestamptz NOT NULL DEFAULT now(), UNIQUE(country_id,city));
CREATE TABLE address (
 address_id bigserial PRIMARY KEY, address varchar(100) NOT NULL,
 address2 varchar(100), district varchar(50) NOT NULL,
 city_id bigint NOT NULL REFERENCES city, postal_code varchar(12),
 phone varchar(24) NOT NULL, last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE language (
 language_id bigserial PRIMARY KEY, name varchar(20) NOT NULL UNIQUE,
 last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE category (
 category_id bigserial PRIMARY KEY, name varchar(25) NOT NULL UNIQUE,
 last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE actor (
 actor_id bigserial PRIMARY KEY, first_name varchar(45) NOT NULL,
 last_name varchar(45) NOT NULL, last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE film (
 film_id bigserial PRIMARY KEY, title varchar(255) NOT NULL,
 description text, release_year year,
 language_id bigint NOT NULL REFERENCES language,
 original_language_id bigint REFERENCES language,
 rental_duration smallint NOT NULL DEFAULT 3 CHECK (rental_duration>0),
 rental_rate numeric(4,2) NOT NULL DEFAULT 4.99 CHECK(rental_rate>=0),
 length smallint CHECK(length>0),
 replacement_cost numeric(5,2) NOT NULL DEFAULT 19.99 CHECK(replacement_cost>=0),
 rating mpaa_rating NOT NULL DEFAULT 'G',
 last_update timestamptz NOT NULL DEFAULT now(),
 special_features text[], fulltext tsvector NOT NULL);
CREATE TABLE film_actor (
 actor_id bigint NOT NULL REFERENCES actor, film_id bigint NOT NULL REFERENCES film,
 last_update timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(actor_id,film_id));
CREATE TABLE film_category (
 film_id bigint NOT NULL REFERENCES film, category_id bigint NOT NULL REFERENCES category,
 last_update timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(film_id,category_id));
CREATE TABLE store (
 store_id bigserial PRIMARY KEY, manager_staff_id bigint NOT NULL UNIQUE,
 address_id bigint NOT NULL REFERENCES address,
 last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE staff (
 staff_id bigserial PRIMARY KEY, first_name varchar(45) NOT NULL,
 last_name varchar(45) NOT NULL, address_id bigint NOT NULL REFERENCES address,
 email varchar(100), store_id bigint NOT NULL REFERENCES store,
 active boolean NOT NULL DEFAULT true, username varchar(50) NOT NULL UNIQUE,
 password varchar(255), last_update timestamptz NOT NULL DEFAULT now(), picture bytea);
ALTER TABLE store ADD CONSTRAINT store_manager_staff_fk
 FOREIGN KEY(manager_staff_id) REFERENCES staff(staff_id)
 DEFERRABLE INITIALLY DEFERRED;
CREATE TABLE customer (
 customer_id bigserial PRIMARY KEY, store_id bigint NOT NULL REFERENCES store,
 first_name varchar(45) NOT NULL, last_name varchar(45) NOT NULL,
 email varchar(100), address_id bigint NOT NULL REFERENCES address,
 activebool boolean NOT NULL DEFAULT true, create_date date NOT NULL DEFAULT current_date,
 last_update timestamptz NOT NULL DEFAULT now(), active integer NOT NULL DEFAULT 1
 CHECK(active IN (0,1)), CHECK(activebool=(active=1)));
CREATE TABLE inventory (
 inventory_id bigserial PRIMARY KEY, film_id bigint NOT NULL REFERENCES film,
 store_id bigint NOT NULL REFERENCES store, last_update timestamptz NOT NULL DEFAULT now());
CREATE TABLE rental (
 rental_id bigserial PRIMARY KEY, rental_date timestamptz NOT NULL,
 inventory_id bigint NOT NULL REFERENCES inventory,
 customer_id bigint NOT NULL REFERENCES customer, return_date timestamptz,
 staff_id bigint NOT NULL REFERENCES staff, last_update timestamptz NOT NULL DEFAULT now(),
 CHECK(return_date IS NULL OR return_date>=rental_date),
 UNIQUE(rental_date,inventory_id,customer_id));
CREATE TABLE payment (
 payment_id bigserial PRIMARY KEY, customer_id bigint NOT NULL REFERENCES customer,
 staff_id bigint NOT NULL REFERENCES staff, rental_id bigint NOT NULL REFERENCES rental,
 amount numeric(7,2) NOT NULL CHECK(amount>=0), payment_date timestamptz NOT NULL);

CREATE INDEX address_city_idx ON address(city_id);
CREATE INDEX city_country_idx ON city(country_id);
CREATE INDEX actor_name_idx ON actor(last_name,first_name);
CREATE INDEX film_language_idx ON film(language_id);
CREATE INDEX film_title_idx ON film(title);
CREATE INDEX film_fulltext_idx ON film USING gin(fulltext);
CREATE INDEX film_actor_film_idx ON film_actor(film_id);
CREATE INDEX film_category_category_idx ON film_category(category_id);
CREATE INDEX staff_store_idx ON staff(store_id);
CREATE INDEX customer_store_idx ON customer(store_id);
CREATE INDEX customer_address_idx ON customer(address_id);
CREATE INDEX inventory_film_store_idx ON inventory(film_id,store_id);
CREATE INDEX rental_inventory_idx ON rental(inventory_id);
CREATE INDEX rental_customer_idx ON rental(customer_id);
CREATE INDEX rental_staff_idx ON rental(staff_id);
CREATE INDEX payment_rental_idx ON payment(rental_id);
CREATE INDEX payment_customer_idx ON payment(customer_id);
CREATE INDEX payment_staff_idx ON payment(staff_id);

-- Installs an invoker-rights generator; executes one atomic append batch.
-- No external extensions, FK bypass, table truncation or explicit ID reset.
CREATE OR REPLACE PROCEDURE dvd_lab.generate_data(p_rows integer)
LANGUAGE plpgsql SET search_path = dvdrental, pg_catalog
AS $body$
DECLARE
 nc integer; nf integer; na integer; ni integer;
 firsts text[] := ARRAY['Amelia','Oliver','Mia','Noah','Isla','Leo','Ava','Ethan',
  'Sofia','Liam','Arjun','Priya','Grace','Lucas','Zoe','Adam','Emma','James'];
 lasts text[] := ARRAY['Smith','Wilson','Patel','Nguyen','Brown','Taylor','Chen',
  'Singh','Martin','Clark','Garcia','Lee','Walker','Ahmed','Thomas','White'];
 adjectives text[] := ARRAY['Silent','Hidden','Last','Golden','Midnight','Lost',
  'Brave','Distant','Winter','Summer','Secret','Crimson','Silver','Forgotten'];
 nouns text[] := ARRAY['Harbour','Journey','Promise','Horizon','River','Garden',
  'Signal','Voyage','Memories','Orchard','Road','Mountain','Letter','Witness'];
 countries text[] := ARRAY['Australia','New Zealand','United Kingdom','United States','Canada','Ireland'];
 cities text[] := ARRAY['Sydney','Melbourne','Auckland','Wellington','London','Manchester',
  'Seattle','Portland','Toronto','Vancouver','Dublin','Cork'];
 districts text[] := ARRAY['New South Wales','Victoria','Auckland','Wellington','Greater London',
  'Greater Manchester','Washington','Oregon','Ontario','British Columbia','Dublin','Cork'];
 postcodes text[] := ARRAY['2000','3000','1010','6011','SW1A 1AA','M1 1AE',
  '98101','97201','M5V 2T6','V6B 1A1','D02 X285','T12 K8AF'];
 phones text[] := ARRAY['+61','+61','+64','+64','+44','+44','+1','+1','+1','+1','+353','+353'];
 country_ids bigint[]; city_ids bigint[]; store_ids bigint[];
 language_ids bigint[]; category_ids bigint[]; actor_ids bigint[];
 film_ids bigint[]; inventory_ids bigint[]; customer_ids bigint[]; address_ids bigint[];
 cid bigint; aid bigint; sid bigint; mid bigint; wid bigint;
 k integer; j integer; seqid bigint; v_title text;
BEGIN
 IF p_rows IS NULL OR p_rows<1 OR p_rows>1000000 THEN
   RAISE EXCEPTION 'rows must be an integer from 1 to 1000000; repeat calls for larger loads';
 END IF;
 -- Serializes this generator, not arbitrary application writes.
 PERFORM pg_advisory_xact_lock(68423, 15);
 nc := greatest(1,ceil(p_rows/10.0)::integer);
 nf := greatest(1,ceil(p_rows/20.0)::integer);
 na := greatest(3,ceil(nf/2.0)::integer);
 ni := 4*nf;

 FOR k IN 1..6 LOOP
   INSERT INTO country(country) VALUES(countries[k]) ON CONFLICT(country) DO NOTHING;
   SELECT country_id INTO cid FROM country WHERE country=countries[k];
   country_ids := array_append(country_ids,cid);
 END LOOP;
 FOR k IN 1..12 LOOP
   INSERT INTO city(city,country_id) VALUES(cities[k],country_ids[(k+1)/2])
     ON CONFLICT(country_id,city) DO NOTHING;
   SELECT city_id INTO cid FROM city WHERE city=cities[k] AND country_id=country_ids[(k+1)/2];
   city_ids := array_append(city_ids,cid);
   -- One fixture store per city. Reuse it on subsequent calls.
   SELECT s.store_id INTO sid FROM store s JOIN address a USING(address_id)
     WHERE a.city_id=cid ORDER BY s.store_id LIMIT 1;
   IF sid IS NULL THEN
     INSERT INTO address(address,district,city_id,postal_code,phone)
       VALUES('10 Market Street',districts[k],cid,postcodes[k],phones[k]||'0000000000')
       RETURNING address_id INTO aid;
     mid := nextval('staff_staff_id_seq');
     INSERT INTO store(manager_staff_id,address_id) VALUES(mid,aid) RETURNING store_id INTO sid;
     FOR j IN 1..2 LOOP
       INSERT INTO address(address,district,city_id,postal_code,phone)
         VALUES((20+j)||' Park Road',districts[k],cid,postcodes[k],phones[k]||'0000000000')
         RETURNING address_id INTO aid;
       wid := CASE WHEN j=1 THEN mid ELSE nextval('staff_staff_id_seq') END;
       INSERT INTO staff(staff_id,first_name,last_name,address_id,email,store_id,username,password)
         VALUES(wid,firsts[1+floor(random()*cardinality(firsts))::int],
           lasts[1+floor(random()*cardinality(lasts))::int],aid,
           'staff.'||wid||'@example.test',sid,'staff_'||wid,NULL);
     END LOOP;
   END IF;
   store_ids := array_append(store_ids,sid);
 END LOOP;
 INSERT INTO language(name) SELECT unnest(ARRAY['English','French','Spanish','Hindi','Japanese','Mandarin'])
   ON CONFLICT(name) DO NOTHING;
 INSERT INTO category(name) SELECT unnest(ARRAY['Action','Animation','Children','Classics','Comedy',
   'Documentary','Drama','Family','Foreign','Games','Horror','Music','New','Sci-Fi','Sports','Travel'])
   ON CONFLICT(name) DO NOTHING;
 SELECT array_agg(language_id ORDER BY language_id) INTO language_ids FROM language;
 SELECT array_agg(category_id ORDER BY category_id) INTO category_ids FROM category;

 WITH ins AS (
 INSERT INTO actor(first_name,last_name)
 SELECT firsts[1+floor(random()*cardinality(firsts))::int],
        lasts[1+floor(random()*cardinality(lasts))::int] FROM generate_series(1,na)
 RETURNING actor_id)
 SELECT array_agg(actor_id ORDER BY actor_id) INTO actor_ids FROM ins;

 -- New IDs are allocated through the owning sequences, never max(id)+1.
 FOR k IN 1..nf LOOP
   seqid := nextval('film_film_id_seq');
   v_title := adjectives[1+floor(random()*cardinality(adjectives))::int]||' '||
      nouns[1+floor(random()*cardinality(nouns))::int]||' ('||seqid||')';
   INSERT INTO film(film_id,title,description,release_year,language_id,rental_duration,
     rental_rate,length,replacement_cost,rating,special_features,fulltext)
   VALUES(seqid,v_title,'A story of friendship, unexpected choices and a journey home.',
     (1980+floor(random()*(extract(year FROM current_date)::int-1980+1)))::integer,
     language_ids[1+floor(random()*cardinality(language_ids))::int],
     (3+floor(random()*5))::smallint,(ARRAY[0.99,2.99,4.99])[1+floor(random()*3)::int],
     (75+floor(random()*91))::smallint,(14.99+floor(random()*16))::numeric(5,2),
     (ARRAY['G','PG','PG-13','R','NC-17']::mpaa_rating[])[1+floor(random()*5)::int],
     CASE WHEN random()<0.5 THEN ARRAY['Trailers','Deleted Scenes']
          ELSE ARRAY['Trailers','Behind the Scenes','Commentaries'] END,
     to_tsvector('english',v_title||' friendship unexpected choices journey home'));
   film_ids := array_append(film_ids,seqid);
   -- Random rotation, then three distinct cast members: never duplicate pairs.
   j := floor(random()*na)::integer;
   INSERT INTO film_actor(actor_id,film_id)
     SELECT actor_ids[1+((j+x)%na)],seqid FROM generate_series(0,2) x;
   INSERT INTO film_category(film_id,category_id)
     VALUES(seqid,category_ids[1+floor(random()*cardinality(category_ids))::int]);
 END LOOP;

 WITH ins AS (
 INSERT INTO address(address,address2,district,city_id,postal_code,phone)
 SELECT (1+floor(random()*500))::int||' '||
   (ARRAY['Park Road','High Street','Lake Avenue','Station Road','River Street'])[1+floor(random()*5)::int],
   CASE WHEN random()<0.2 THEN 'Unit '||(1+floor(random()*40))::int END,
   districts[1+((g-1)%12)],city_ids[1+((g-1)%12)],postcodes[1+((g-1)%12)],
   phones[1+((g-1)%12)]||'0000000000' FROM generate_series(1,nc) g
 RETURNING address_id)
 SELECT array_agg(address_id ORDER BY address_id) INTO address_ids FROM ins;
 WITH ins AS (
 INSERT INTO customer(store_id,first_name,last_name,email,address_id,create_date)
 SELECT store_ids[1+((g-1)%12)],firsts[1+floor(random()*cardinality(firsts))::int],
   lasts[1+floor(random()*cardinality(lasts))::int],
   'customer.'||address_ids[g]||'@example.test',address_ids[g],
   current_date-365-floor(random()*730)::integer FROM generate_series(1,nc) g
 RETURNING customer_id)
 SELECT array_agg(customer_id ORDER BY customer_id) INTO customer_ids FROM ins;
 WITH ins AS (
 INSERT INTO inventory(film_id,store_id)
 SELECT film_ids[1+((g-1)%nf)],store_ids[1+(((g-1)%nc)%12)] FROM generate_series(1,ni) g
 RETURNING inventory_id)
 SELECT array_agg(inventory_id ORDER BY inventory_id) INTO inventory_ids FROM ins;

 -- Each new copy has <=5 rentals in separated 14-day windows. An open
 -- rental can occur only on its last use and starts within the last 2 days.
 -- Customers and checkout staff belong to that copy's store.
 WITH plan AS MATERIALIZED (
 SELECT g,1+((g-1)%ni) AS ix,(g-1)/ni AS slot,
   CASE WHEN g+ni>p_rows AND random()<0.1 THEN true ELSE false END AS is_open,
   random() AS jitter,1+floor(random()*7)::integer AS days_out
 FROM generate_series(1,p_rows) g), ins AS (
 INSERT INTO rental(rental_date,inventory_id,customer_id,return_date,staff_id)
 SELECT t.started,i.inventory_id,customer_ids[1+((p.ix-1)%nc)],
   CASE WHEN p.is_open THEN NULL ELSE t.started+make_interval(days=>p.days_out) END,
   s.staff_id
 FROM plan p JOIN inventory i ON i.inventory_id=inventory_ids[p.ix]
 JOIN LATERAL (SELECT st.staff_id FROM staff st WHERE st.store_id=i.store_id
   ORDER BY st.staff_id LIMIT 1 OFFSET (p.g%2)) s ON true
 CROSS JOIN LATERAL (SELECT CASE WHEN p.is_open THEN statement_timestamp()-interval '1 day'-interval '1 day'*p.jitter
   ELSE date_trunc('day',statement_timestamp())-interval '90 days'+
        make_interval(days=>p.slot*14)+interval '2 days'*p.jitter END AS started) t
 RETURNING rental_id,customer_id,staff_id,inventory_id,rental_date,return_date)
 INSERT INTO payment(customer_id,staff_id,rental_id,amount,payment_date)
 SELECT r.customer_id,r.staff_id,r.rental_id,
   f.rental_rate+CASE WHEN r.return_date IS NULL THEN 0 ELSE
   greatest(0,ceil(extract(epoch FROM(r.return_date-r.rental_date))/86400)::int-f.rental_duration)*0.99 END,
   r.rental_date+interval '1 minute'
 FROM ins r JOIN inventory i USING(inventory_id) JOIN film f USING(film_id);
 RAISE NOTICE 'Appended: % rentals/payments, % customers/addresses, % films, % actors, % inventory, % cast links, % category links',
   p_rows,nc,nf,na,ni,3*nf,nf;
END;
$body$;
-- Keep the procedure callable only by its owner unless explicitly granted.
REVOKE ALL ON PROCEDURE dvd_lab.generate_data(integer) FROM PUBLIC;
COMMIT;

\echo 'Created dvdrental and dvd_lab schemas; no application rows were loaded.'

