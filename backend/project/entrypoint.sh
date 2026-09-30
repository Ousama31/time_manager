#!/bin/sh
set -eu

while ! pg_isready -q -h "${PGHOST:-db}" -U "${PGUSER:-postgres}"; do
  echo "Wait until the container of the database is usable"
  sleep 2
done

bin/time_manager eval "TimeManager.Release.migrate()"
exec bin/time_manager start
