#!/usr/bin/env bash
# Starts PostgreSQL directly with the detected installed major version and configured data directory.
set -euo pipefail

pg_major="$(ls -1 /etc/postgresql | sort -V | tail -n 1)"
if [[ -z "${pg_major}" ]]; then
  echo "No PostgreSQL version found under /etc/postgresql" >&2
  exit 1
fi

exec "/usr/lib/postgresql/${pg_major}/bin/postgres" \
  -D "/var/lib/postgresql/${pg_major}/main" \
  -c "config_file=/etc/postgresql/${pg_major}/main/postgresql.conf" \
  -c "listen_addresses=*"
