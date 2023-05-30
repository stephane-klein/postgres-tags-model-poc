\echo "Database cleaning..."
SET client_min_messages TO WARNING;

DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

\echo "Database cleaned"
