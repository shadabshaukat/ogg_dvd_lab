#!/usr/bin/env bash
set -u
export PGPASSFILE="$HOME/ogg_dvd_lab/.pgpass"
export PGAPPNAME=ogg_lab_seed
export PGOPTIONS='-c lock_timeout=5s -c statement_timeout=10min'
run_dir="$HOME/ogg_dvd_lab/run_20260928"
date -u +SEED_START=%FT%TZ
psql -X -w -h 10.180.2.27 -U postgres -d postgres -v ON_ERROR_STOP=1 -v rows=1000000 -f "$HOME/ogg_dvd_lab/01_load_source.sql"
rc=$?
printf '%s\n' "$rc" > "$run_dir/seed.exit"
date -u +SEED_END=%FT%TZ
exit "$rc"
