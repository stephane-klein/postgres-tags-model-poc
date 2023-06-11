\echo "Schema creating..."

SET client_min_messages TO WARNING;

CREATE TABLE public.contact_tags (
    id             SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    contact_counts INTEGER DEFAULT 0
);
CREATE INDEX contact_tags_name_index ON public.contact_tags (name);
CREATE INDEX contact_tags_contact_counts_index ON public.contact_tags (contact_counts);

CREATE TABLE public.contacts (
    id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name     VARCHAR NOT NULL,
    tags     INTEGER[]
);
CREATE INDEX contacts_index ON public.contacts USING GIN (tags);

DROP FUNCTION IF EXISTS public.insert_contact;
CREATE FUNCTION public.insert_contact(
    _name VARCHAR,
    tags VARCHAR[]
) RETURNS UUID AS $$
    INSERT INTO
        public.contact_tags
    (
        name
    )
    SELECT
        tag_name
    FROM
        UNNEST(tags) AS tag_name
    WHERE
        tag_name NOT IN (
            SELECT contact_tags.name
            FROM public.contact_tags
            WHERE contact_tags.name = tag_name
        );

    INSERT INTO
        public.contacts
    (
        name,
        tags
    )
    SELECT
        _name,
        ARRAY_AGG(contact_tags.id) AS tags
    FROM
        UNNEST(tags) AS tag_name
    LEFT JOIN
        public.contact_tags
    ON
        contact_tags.name = tag_name
    RETURNING id;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS public.get_and_maybe_insert_tags;
CREATE FUNCTION public.get_and_maybe_insert_tags(
    tag_names VARCHAR[]
) RETURNS INTEGER[] AS $$
    INSERT INTO
        public.contact_tags
    (
        name
    )
    SELECT
        tag_name
    FROM
        UNNEST(tag_names) AS tag_name
    WHERE
        tag_name NOT IN (
            SELECT contact_tags.name
            FROM public.contact_tags
            WHERE contact_tags.name = tag_name
        );

    SELECT
        ARRAY_AGG(contact_tags.id) AS tags
    FROM
        UNNEST(tag_names) AS tag_name
    LEFT JOIN
        public.contact_tags
    ON
        contact_tags.name = tag_name;
$$ LANGUAGE SQL;

\echo "Schema created"
