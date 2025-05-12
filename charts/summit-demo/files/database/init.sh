#!/bin/sh

set -e

cd "$(dirname "$(realpath "$0")")"

export PGPASSWORD="${POSTGRESQL_PASSWORD:-claimdb}"

exec psql -f ./init.sql -U "${POSTGRESQL_USER:-claimdb}" -d "${POSTGRESQL_DATABASE:-claimdb}"
