--
-- PostgreSQL database dump
--

\restrict E7fky5mQvnukjDLzf8RdWmd4nNMqe56shoH7N0aTAM6Tc3sMPHYOwD7A2px1P4H

-- Dumped from database version 14.24 (Ubuntu 14.24-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: actor_actor_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.actor_actor_id_seq', 32500, true);


--
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.address_address_id_seq', 130036, true);


--
-- Name: category_category_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.category_category_id_seq', 4816, true);


--
-- Name: city_city_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.city_city_id_seq', 3612, true);


--
-- Name: country_country_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.country_country_id_seq', 1806, true);


--
-- Name: customer_customer_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.customer_customer_id_seq', 130000, true);


--
-- Name: film_film_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.film_film_id_seq', 65000, true);


--
-- Name: inventory_inventory_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.inventory_inventory_id_seq', 260000, true);


--
-- Name: language_language_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.language_language_id_seq', 1806, true);


--
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.payment_payment_id_seq', 1300000, true);


--
-- Name: rental_rental_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.rental_rental_id_seq', 1300000, true);


--
-- Name: staff_staff_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.staff_staff_id_seq', 24, true);


--
-- Name: store_store_id_seq; Type: SEQUENCE SET; Schema: dvdrental; Owner: -
--

SELECT pg_catalog.setval('dvdrental.store_store_id_seq', 12, true);


--
-- PostgreSQL database dump complete
--

\unrestrict E7fky5mQvnukjDLzf8RdWmd4nNMqe56shoH7N0aTAM6Tc3sMPHYOwD7A2px1P4H

