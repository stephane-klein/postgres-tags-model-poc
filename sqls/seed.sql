SET client_min_messages TO WARNING;

\echo "Database cleaning..."

CREATE SCHEMA IF NOT EXISTS utils;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA utils;

DROP SCHEMA IF EXISTS main CASCADE;
CREATE SCHEMA main;

\echo "Database cleaned"

\echo "Schema creating..."

CREATE TABLE main.contacts (
    id       UUID PRIMARY KEY DEFAULT utils.uuid_generate_v4(),
    name     VARCHAR NOT NULL,
    tags     INTEGER[]
);
CREATE INDEX contacts_index ON main.contacts USING GIN (tags);

\i contact_tags_system.sql

\echo "Schema created"
