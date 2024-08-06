-- vim: set syntax=sql:
CREATE TABLE main.contact_tags (
    id     SERIAL PRIMARY KEY,
    name   TEXT NOT NULL,

    contact_counts INTEGER DEFAULT 0
);
CREATE INDEX contact_tags_name_index ON main.contact_tags (name);
CREATE INDEX contact_tags_contact_counts_index ON main.contact_tags (contact_counts);

DROP VIEW IF EXISTS main.contacts_with_tag_names CASCADE;
CREATE VIEW main.contacts_with_tag_names AS
    WITH exploded AS (
         SELECT
             contacts.id,
             tag_id
         FROM
             main.contacts
         CROSS JOIN UNNEST(contacts.tags) AS tag_id
     )
     SELECT
         contacts.*,
         ARRAY_AGG(note_tags.name) FILTER (WHERE note_tags.name IS NOT NULL) AS tag_names
     FROM
         main.contacts
     LEFT JOIN
         exploded
     ON
         contacts.id = exploded.id
     LEFT JOIN
         main.contact_tags
     ON
         exploded.tag_id = contact_tags.id
     GROUP BY
         contacts.id;

DROP VIEW IF EXISTS main.contacts_with_tags CASCADE;
CREATE VIEW main.contacts_with_tags AS
    WITH exploded AS (
         SELECT
             contacts.id,
             tag_id
         FROM
             main.contacts
         CROSS JOIN UNNEST(contacts.tags) AS tag_id
     )
     SELECT
         contacts.*,
         JSON_AGG(
            json_build_object(
                 'id',
                 main.contact_tags.id,
                 'name',
                 main.contact_tags.name
            )
        )
     FROM
         main.contacts
     LEFT JOIN
         exploded
     ON
         contacts.id = exploded.id
     LEFT JOIN
         main.contact_tags
     ON
         exploded.tag_id = contact_tags.id
     GROUP BY
         contacts.id;

DROP FUNCTION IF EXISTS main.get_and_maybe_insert_contact_tags;
CREATE FUNCTION main.get_and_maybe_insert_contact_tags(
    tag_names VARCHAR[]
) RETURNS INTEGER[] AS $$
    INSERT INTO
        main.contact_tags
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
            FROM main.contact_tags
            WHERE contact_tags.name = tag_name
        );

    SELECT
        ARRAY_AGG(contact_tags.id) AS tags
    FROM
        UNNEST(tag_names) AS tag_name
    LEFT JOIN
        main.contact_tags
    ON
        contact_tags.name = tag_name;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS main.compute_contact_tags_cache;
CREATE FUNCTION main.compute_contact_tags_cache(
    tag_ids INTEGER[]
) RETURNS VOID AS $$
    UPDATE
        main.contact_tags
    SET
        contact_counts=contact_count_computation.contact_count
    FROM (
        SELECT
            contact_tags.id AS contact_tag_id,
            COUNT(contacts.id) AS contact_count
        FROM
            main.contact_tags
        LEFT JOIN
            main.contacts
        ON
            contact_tags.id = ANY(contacts.tags)
        WHERE
            contact_tags.id = ANY(tag_ids)
        GROUP BY contact_tags.id
    ) AS contact_count_computation
    WHERE
        contact_tags.id=contact_count_computation.contact_tag_id;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS main.compute_all_contact_tags_cache;
CREATE FUNCTION main.compute_all_contact_tags_cache(
) RETURNS VOID AS $$
    UPDATE
        main.contact_tags
    SET
        contact_counts=contact_count_computation.contact_count
    FROM (
        SELECT
            contact_tags.id AS contact_tag_id,
            COUNT(contacts.id) AS contact_count
        FROM
            main.contact_tags
        LEFT JOIN
            main.contacts
        ON
            contact_tags.id = ANY(contacts.tags)
        GROUP BY contact_tags.id
    ) AS contact_count_computation
    WHERE
        contact_tags.id=contact_count_computation.contact_tag_id;
$$ LANGUAGE SQL;

DROP TRIGGER IF EXISTS on_contact_tags_updated_then_compute_contact_tags_cache ON main.contacts;
DROP FUNCTION IF EXISTS main.on_contact_tags_updated_then_compute_contact_tags_cache();

CREATE FUNCTION main.on_contact_tags_updated_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM main.compute_contact_tags_cache(
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
    ON main.contacts
    FOR EACH ROW
    WHEN (OLD.tags IS DISTINCT FROM  NEW.tags)
    EXECUTE PROCEDURE main.on_contact_tags_updated_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contact_tags_inserted_then_compute_contact_tags_cache ON main.contacts;
DROP FUNCTION IF EXISTS main.on_contact_tags_inserted_then_compute_contact_tags_cache();

CREATE FUNCTION main.on_contact_tags_inserted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM main.compute_contact_tags_cache(NEW.tags);

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_inserted_then_compute_contact_tags_cache
    AFTER INSERT
    ON main.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE main.on_contact_tags_inserted_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contacs_tags_deleted_then_compute_contact_tags_cache ON main.contacts;
DROP FUNCTION IF EXISTS main.on_contacs_tags_deleted_then_compute_contact_tags_cache();

CREATE FUNCTION main.on_contact_tags_deleted_then_compute_contact_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM main.compute_contact_tags_cache(OLD.tags);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_deleted_then_compute_contact_tags_cache
    AFTER DELETE
    ON main.contacts
    FOR EACH ROW
    EXECUTE PROCEDURE main.on_contact_tags_deleted_then_compute_contact_tags_cache();

DROP TRIGGER IF EXISTS on_contact_tags_deleted_then_remove_tag_in_contacts ON main.contact_tags;
DROP FUNCTION IF EXISTS main.on_contact_tags_deleted_then_remove_tag_in_contacts();

CREATE FUNCTION main.on_contact_tags_deleted_then_remove_tag_in_contacts() RETURNS TRIGGER AS $$
BEGIN
    UPDATE
        main.contacts
    SET
        tags=ARRAY_REMOVE(contacts.tags, OLD.id)
    WHERE
        OLD.id = ANY(contacts.tags);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_contact_tags_deleted_then_remove_tag_in_contacts
    AFTER DELETE
    ON main.contact_tags
    FOR EACH ROW
    EXECUTE PROCEDURE main.on_contact_tags_deleted_then_remove_tag_in_contacts();

