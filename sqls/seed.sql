SET client_min_messages TO WARNING;

\echo "Database cleaning..."

DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

\echo "Database cleaned"

\echo "Schema creating..."

CREATE TABLE public.contacts (
    id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name     VARCHAR NOT NULL,
    tags     INTEGER[]
);
CREATE INDEX contacts_index ON public.contacts USING GIN (tags);

\i contact_tags_system.sql

\echo "Schema created"
