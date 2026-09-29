-- Run on the SOURCE through the bastion. This changes lab payment data.
-- Example: psql ... -v operation=update -v rows=100 -f 02_dml_source.sql
-- Operations: update, delete, upsert. Each call commits one complete batch.
-- ORDER BY random() scans payment: selection time is part of the workload.
\set ON_ERROR_STOP on
\timing on

\if :{?operation}
\else
  \set operation update
\endif
\if :{?rows}
\else
  \set rows 100
\endif

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '2min';

-- Pass psql variables safely into the anonymous PL/pgSQL block.
SET LOCAL dvd_lab.dml_operation = :'operation';
SET LOCAL dvd_lab.dml_rows = :'rows';

DO $workload$
DECLARE
  v_operation text := lower(current_setting('dvd_lab.dml_operation'));
  v_rows_text text := current_setting('dvd_lab.dml_rows');
  v_rows integer;
  v_ids bigint[];
  v_affected bigint;
BEGIN
  IF v_operation NOT IN ('update', 'delete', 'upsert') THEN
    RAISE EXCEPTION 'operation must be update, delete, or upsert';
  END IF;
  IF v_rows_text !~ '^[0-9]{1,6}$' THEN
    RAISE EXCEPTION 'rows must be an integer from 1 to 100000';
  END IF;
  v_rows := v_rows_text::integer;
  IF v_rows < 1 OR v_rows > 100000 THEN
    RAISE EXCEPTION 'rows must be an integer from 1 to 100000';
  END IF;

  -- Pick distinct random payments and lock them until this batch commits.
  -- Skip rows being changed by other sessions rather than waiting for them.
  SELECT array_agg(s.payment_id)
  INTO v_ids
  FROM (
    SELECT payment_id
    FROM dvdrental.payment
    ORDER BY random()
    LIMIT v_rows
    FOR UPDATE SKIP LOCKED
  ) AS s;

  -- Stop instead of silently running partial or empty batches.
  IF coalesce(cardinality(v_ids), 0) < v_rows THEN
    RAISE EXCEPTION 'Requested % rows, but only % unlocked payments are available',
      v_rows, coalesce(cardinality(v_ids), 0);
  END IF;

  IF v_operation = 'update' THEN
    -- Change non-key columns; wrap the amount to stay within numeric(7,2).
    UPDATE dvdrental.payment
    SET amount = mod(amount + 1.00, 10000.00),
        payment_date = clock_timestamp()
    WHERE payment_id = ANY(v_ids);

  ELSIF v_operation = 'delete' THEN
    -- Payment has no referencing child tables in this lab schema.
    DELETE FROM dvdrental.payment
    WHERE payment_id = ANY(v_ids);

  ELSE
    -- For 100 selected payments, reuse 50 IDs (conflict updates) and allocate
    -- 50 fresh IDs (inserts). For an odd batch, the extra row is an update.
    -- Copy valid parent IDs, and use the existing sequence for all fresh IDs.
    INSERT INTO dvdrental.payment
      (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
    SELECT
      CASE WHEN s.position % 2 = 1 THEN p.payment_id
           ELSE nextval('dvdrental.payment_payment_id_seq'::regclass) END,
      p.customer_id, p.staff_id, p.rental_id,
      mod(p.amount + 1.00, 10000.00), clock_timestamp()
    FROM unnest(v_ids) WITH ORDINALITY AS s(payment_id, position)
    JOIN dvdrental.payment AS p ON p.payment_id = s.payment_id
    WHERE true
    ON CONFLICT (payment_id) DO UPDATE
    SET amount = EXCLUDED.amount,
        payment_date = EXCLUDED.payment_date;
  END IF;

  GET DIAGNOSTICS v_affected = ROW_COUNT;
  RAISE NOTICE 'operation=%, affected_rows=%, source_time=%',
    v_operation, v_affected, clock_timestamp();
END;
$workload$;

COMMIT;

