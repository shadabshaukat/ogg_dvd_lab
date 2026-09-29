#!/usr/bin/env bash
set -euo pipefail
export PGPASSFILE="$HOME/ogg_dvd_lab/.pgpass"
export PGAPPNAME=ogg_lab_writer
run_dir="$HOME/ogg_dvd_lab/run_20260928"
touch "$run_dir/writer.run"
batch=0
while test -e "$run_dir/writer.run" && test "$batch" -lt 300; do
  printf 'BATCH_START|%s|%s\n' "$((batch+1))" "$(date -u +%FT%TZ)"
  psql -X -w -v ON_ERROR_STOP=1 -v rows=1000 \
    -h 10.180.2.27 -U postgres -d postgres \
    -f "$HOME/ogg_dvd_lab/01_load_source.sql"
  batch=$((batch+1))
  printf 'BATCH_COMMIT|%s|%s\n' "$batch" "$(date -u +%FT%TZ)"
  sleep 2
done
printf 'WRITER_STOP|%s|%s\n' "$batch" "$(date -u +%FT%TZ)"
