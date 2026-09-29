#!/usr/bin/env bash
run_dir="$HOME/ogg_dvd_lab/run_20260928"
export PGPASSFILE="$HOME/ogg_dvd_lab/.pgpass"
export PGAPPNAME=ogg_lab_restore
export PGOPTIONS='-c lock_timeout=5s -c statement_timeout=20min'
date -u +RESTORE_START=%Y-%m-%dT%H:%M:%SZ
pg_restore -w -h 10.180.2.199 -U postgres -d postgres --jobs=4 --exit-on-error --no-owner --no-acl --no-tablespaces "$run_dir/dump"
restore_rc=$?
printf '%s\n' "$restore_rc" > "$run_dir/restore.exit"
date -u +RESTORE_END=%Y-%m-%dT%H:%M:%SZ
exit "$restore_rc"
