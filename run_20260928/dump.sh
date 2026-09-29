#!/usr/bin/env bash
set -u
export PGPASSFILE="$HOME/ogg_dvd_lab/.pgpass"
export PGAPPNAME=ogg_lab_dump
run_dir="$HOME/ogg_dvd_lab/run_20260928"
date -u +DUMP_START=%FT%TZ
pg_dump -h 10.180.2.27 -U postgres -d postgres \
  --format=directory --jobs=4 --compress=6 --lock-wait-timeout=5s \
  --snapshot=00000004-00005BEE-1 --schema=dvdrental --schema=dvd_lab \
  --quote-all-identifiers --no-owner --no-acl --no-publications --no-subscriptions \
  --file="$run_dir/dump"
rc=$?
printf '%s\n' "$rc" > "$run_dir/dump.exit"
date -u +DUMP_END=%FT%TZ
exit "$rc"
