SELECT jsonb_build_object(
  'sampled_at', clock_timestamp(),
  'phase', :'phase',
  'current_lsn', pg_current_wal_lsn(),
  'wal_bytes', (SELECT wal_bytes FROM pg_stat_wal),
  'wal_stats_reset', (SELECT stats_reset FROM pg_stat_wal),
  'pg_wal_bytes', (SELECT coalesce(sum(size),0) FROM pg_ls_waldir()),
  'published_tables', (SELECT count(*) FROM pg_publication_tables WHERE pubname='ogg_migration_pub'),
  'slots', (SELECT coalesce(jsonb_agg(jsonb_build_object(
    'slot_name',slot_name,'plugin',plugin,'temporary',temporary,'active',active,
    'restart_lsn',restart_lsn,'confirmed_flush_lsn',confirmed_flush_lsn,
    'retained_bytes',pg_wal_lsn_diff(pg_current_wal_lsn(),restart_lsn),
    'wal_status',wal_status,'safe_wal_size',safe_wal_size,
    'xmin_age',age(xmin),'catalog_xmin_age',age(catalog_xmin)
  ) ORDER BY slot_name),'[]'::jsonb) FROM pg_replication_slots WHERE database=current_database()),
  'transactions', (SELECT coalesce(jsonb_agg(jsonb_build_object(
    'pid',pid,'app',application_name,'state',state,
    'xact_seconds',extract(epoch FROM clock_timestamp()-xact_start),
    'xmin_age',age(backend_xmin),'wait_type',wait_event_type,'wait',wait_event,
    'blockers',pg_blocking_pids(pid)
  ) ORDER BY pid),'[]'::jsonb) FROM pg_stat_activity
    WHERE datname=current_database() AND pid<>pg_backend_pid() AND xact_start IS NOT NULL),
  'blocked_sessions', (SELECT count(*) FROM pg_stat_activity WHERE datname=current_database() AND cardinality(pg_blocking_pids(pid))>0),
  'estimated_dead_tuples', (SELECT coalesce(sum(n_dead_tup),0) FROM pg_stat_user_tables WHERE schemaname='dvdrental'),
  'deadlocks', (SELECT deadlocks FROM pg_stat_database WHERE datname=current_database()),
  'temp_bytes', (SELECT temp_bytes FROM pg_stat_database WHERE datname=current_database()),
  'decoding', (SELECT coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) FROM pg_stat_replication_slots s)
);
