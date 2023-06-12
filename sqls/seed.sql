SET client_min_messages TO WARNING;

\echo "Database cleaning..."

DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

\echo "Database cleaned"

\echo "Schema creating..."

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

DROP FUNCTION IF EXISTS public.compute_contact_tags_cache;
CREATE FUNCTION public.compute_contact_tags_cache(
    tag_ids INTEGER[]
) RETURNS VOID AS $$
    UPDATE
        public.contact_tags
    SET
        contact_counts=contact_count_computation.contact_count
    FROM (
        SELECT
            contact_tags.id AS contact_tag_id,
            COUNT(contacts.id) AS contact_count
        FROM
            contact_tags
        LEFT JOIN
            contacts
        ON
            contact_tags.id = ANY(contacts.tags)
        WHERE
            contact_tags.id = ANY(tag_ids)
        GROUP BY contact_tags.id
    ) AS contact_count_computation
    WHERE
        contact_tags.id=contact_count_computation.contact_tag_id;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS public.compute_all_contact_tags_cache;
CREATE FUNCTION public.compute_all_contact_tags_cache(
) RETURNS VOID AS $$
    UPDATE
        public.contact_tags
    SET
        contact_counts=contact_count_computation.contact_count
    FROM (
        SELECT
            contact_tags.id AS contact_tag_id,
            COUNT(contacts.id) AS contact_count
        FROM
            contact_tags
        LEFT JOIN
            contacts
        ON
            contact_tags.id = ANY(contacts.tags)
        GROUP BY contact_tags.id
    ) AS contact_count_computation
    WHERE
        contact_tags.id=contact_count_computation.contact_tag_id;
$$ LANGUAGE SQL;

\echo "on_contacts_tags_updated_then_compute_contact_tags_cache trigger creating..."

DROP TRIGGER IF EXISTS on_contacts_tags_updated_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS on_contacts_tags_updated_then_compute_contact_tags_cache();

CREATE FUNCTION on_contacts_tags_updated_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.compute_contact_tags_cache(
        ARRAY(
            SELECT DISTINCT *
            FROM UNNEST(
                ARRAY_CAT(
                    OLD.tags,
                    NEW.tags
                )
            )
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contacts_tags_updated_then_compute_contact_tags_cache
    AFTER UPDATE
    ON public.contacts
    FOR EACH ROW
    WHEN (OLD.tags IS DISTINCT FROM  NEW.tags)
    EXECUTE PROCEDURE on_contacts_tags_updated_then_compute_contact_tags_cache();

\echo "... on_contacts_tags_updated_then_compute_contact_tags_cache created"

\echo "on_contacts_tags_inserted_then_compute_contact_tags_cache trigger creating..."

DROP TRIGGER IF EXISTS on_contacts_tags_inserted_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS on_contacts_tags_inserted_then_compute_contact_tags_cache();

CREATE FUNCTION on_contacts_tags_inserted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.compute_contact_tags_cache(NEW.tags);

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contacts_tags_inserted_then_compute_contact_tags_cache
    AFTER INSERT
    ON public.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE on_contacts_tags_inserted_then_compute_contact_tags_cache();

\echo "... on_contacts_tags_inserted_then_compute_contact_tags_cache created"

\echo "on_contacts_tags_deleted_then_compute_contact_tags_cache trigger creating..."

DROP TRIGGER IF EXISTS on_contacts_tags_deleted_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS on_contacts_tags_deleted_then_compute_contact_tags_cache();

CREATE FUNCTION on_contacts_tags_deleted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.compute_contact_tags_cache(OLD.tags);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contacts_tags_deleted_then_compute_contact_tags_cache
    AFTER DELETE
    ON public.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE on_contacts_tags_deleted_then_compute_contact_tags_cache();

\echo "... on_contacts_tags_deleted_then_compute_contact_tags_cache created"

\echo "Schema created"
