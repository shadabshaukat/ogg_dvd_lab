SET TIME ZONE 'UTC';
SET DateStyle = 'ISO, YMD';
SET IntervalStyle = 'postgres';
SET extra_float_digits = 3;
SET bytea_output = 'hex';

SELECT format($fmt$
SELECT %L AS table_name, count(*) AS row_count,
       md5(string_agg(md5(t::text), '' ORDER BY md5(t::text) COLLATE "C")) AS fingerprint
FROM %I.%I t;
$fmt$, c.relname, n.nspname, c.relname)
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'dvdrental' AND c.relkind = 'r'
ORDER BY c.relname
\gexec
