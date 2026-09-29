SELECT format(
  'SELECT %L AS sequence_name, (SELECT max(%I) FROM %I.%I) AS max_id, '
  || 'last_value, is_called FROM %s;',
  pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname),
  a.attname, n.nspname, c.relname,
  pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname)
)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid
WHERE n.nspname = 'dvdrental' AND c.relkind = 'r'
  AND a.attnum > 0 AND NOT a.attisdropped
  AND pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) IS NOT NULL
ORDER BY c.relname
\gexec
