#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec postgres-test sh -c "psql -U \$POSTGRES_USER \$POSTGRES_DB"
