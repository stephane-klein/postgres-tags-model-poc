#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker-compose exec postgres-test sh -c "pg_prove -d \$POSTGRES_DB -U \$POSTGRES_USER /${@:-"sqls/tests/*"}"
