#!/usr/bin/env bash
set -euo pipefail
export PGPASSFILE="$HOME/ogg_dvd_lab/.pgpass"
export PGAPPNAME=ogg_lab_monitor
run_dir="$HOME/ogg_dvd_lab/run_20260928"
touch "$run_dir/monitor.run"
sample=0
while test -e "$run_dir/monitor.run" && test "$sample" -lt 1800; do
  phase=$(cat "$run_dir/phase")
  psql -X -w -At -v ON_ERROR_STOP=1 -v phase="$phase" \
    -h 10.180.2.27 -U postgres -d postgres \
    -f "$run_dir/monitor_source.sql" >> "$run_dir/source_monitor.jsonl"
  if (( sample % 5 == 0 )); then
    printf '%s|%s|' "$(date -u +%FT%TZ)" "$phase" >> "$run_dir/source_disk.log"
    ssh -n -o BatchMode=yes ubuntu@10.180.2.27 \
      'sudo df -B1 --output=avail,pcent,target /var/lib/postgresql/14/main/pg_wal | tail -1' \
      >> "$run_dir/source_disk.log"
  fi
  sample=$((sample+1))
  sleep 2
done
