#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker-compose exec postgres-test sh -c "pg_prove -v -d \$POSTGRES_DB -U \$POSTGRES_USER /${@:-"sqls/tests/*"}"
