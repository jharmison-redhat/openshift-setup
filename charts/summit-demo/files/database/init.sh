#!/bin/sh

set -e

export PGPASSWORD="${POSTGRESQL_PASSWORD:-claimdb}"

exec psql -f /opt/app-root/src/postgresql-start/init.sql -U "${POSTGRESQL_USER:-claimdb}" -d "${POSTGRESQL_DATABASE:-claimdb}"
