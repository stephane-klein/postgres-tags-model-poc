-- vim: set syntax=sql:
CREATE TABLE public.contact_tags (
    id     SERIAL PRIMARY KEY,
    name   TEXT NOT NULL,

    contact_counts INTEGER DEFAULT 0
);
CREATE INDEX contact_tags_name_index ON public.contact_tags (name);
CREATE INDEX contact_tags_contact_counts_index ON public.contact_tags (contact_counts);

CREATE VIEW public.contacts_with_tag_names AS
    WITH exploded AS (
         SELECT
             contacts.id,
             tag_id
         FROM
             public.contacts
         CROSS JOIN UNNEST(contacts.tags) AS tag_id
     )
     SELECT
         contacts.*,
         ARRAY_AGG(public.contact_tags.name) AS tag_names
     FROM
         public.contacts
     LEFT JOIN
         exploded
     ON
         contacts.id = exploded.id
     LEFT JOIN
         public.contact_tags
     ON
         exploded.tag_id = contact_tags.id
     GROUP BY
         contacts.id;

CREATE VIEW public.contacts_with_tags AS
    WITH exploded AS (
         SELECT
             contacts.id,
             tag_id
         FROM
             public.contacts
         CROSS JOIN UNNEST(contacts.tags) AS tag_id
     )
     SELECT
         contacts.*,
         JSON_AGG(
            json_build_object(
                 'id',
                 public.contact_tags.id,
                 'name',
                 public.contact_tags.name
            )
        )
     FROM
         public.contacts
     LEFT JOIN
         exploded
     ON
         contacts.id = exploded.id
     LEFT JOIN
         public.contact_tags
     ON
         exploded.tag_id = contact_tags.id
     GROUP BY
         contacts.id;

DROP FUNCTION IF EXISTS public.get_and_maybe_insert_contact_tags;
CREATE FUNCTION public.get_and_maybe_insert_contact_tags(
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
            public.contact_tags
        LEFT JOIN
            public.contacts
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
            public.contact_tags
        LEFT JOIN
            public.contacts
        ON
            contact_tags.id = ANY(contacts.tags)
        GROUP BY contact_tags.id
    ) AS contact_count_computation
    WHERE
        contact_tags.id=contact_count_computation.contact_tag_id;
$$ LANGUAGE SQL;

DROP TRIGGER IF EXISTS on_contact_tags_updated_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS public.on_contact_tags_updated_then_compute_contact_tags_cache();

CREATE FUNCTION public.on_contact_tags_updated_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
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

CREATE TRIGGER on_contact_tags_updated_then_compute_contact_tags_cache
    AFTER UPDATE
    ON public.contacts
    FOR EACH ROW
    WHEN (OLD.tags IS DISTINCT FROM  NEW.tags)
    EXECUTE PROCEDURE public.on_contact_tags_updated_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contact_tags_inserted_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS public.on_contact_tags_inserted_then_compute_contact_tags_cache();

CREATE FUNCTION public.on_contact_tags_inserted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.compute_contact_tags_cache(NEW.tags);

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_inserted_then_compute_contact_tags_cache
    AFTER INSERT
    ON public.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE public.on_contact_tags_inserted_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contacs_tags_deleted_then_compute_contact_tags_cache ON public.contacts;
DROP FUNCTION IF EXISTS public.on_contacs_tags_deleted_then_compute_contact_tags_cache();

CREATE FUNCTION public.on_contact_tags_deleted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.compute_contact_tags_cache(OLD.tags);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_deleted_then_compute_contact_tags_cache
    AFTER DELETE
    ON public.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE public.on_contact_tags_deleted_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contact_tags_deleted_then_remove_tag_in_contacts ON public.contact_tags;
DROP FUNCTION IF EXISTS public.on_contact_tags_deleted_then_remove_tag_in_contacts();

CREATE FUNCTION public.on_contact_tags_deleted_then_remove_tag_in_contacts() RETURNS TRIGGER AS $$
BEGIN
    UPDATE
        public.contacts
    SET
        tags=ARRAY_REMOVE(contacts.tags, OLD.id)
    WHERE
        OLD.id = ANY(contacts.tags);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_deleted_then_remove_tag_in_contacts
    AFTER DELETE
    ON public.contact_tags
    FOR EACH ROW
    EXECUTE PROCEDURE public.on_contact_tags_deleted_then_remove_tag_in_contacts();

