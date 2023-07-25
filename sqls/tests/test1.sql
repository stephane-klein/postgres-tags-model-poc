BEGIN;
SELECT plan(7);

SELECT has_table('main'::name, 'contacts'::name);
SELECT has_table('main'::name, 'contact_tags'::name);

DELETE FROM main.contacts CASCADE;
DELETE FROM main.contact_tags CASCADE;
ALTER SEQUENCE main.contact_tags_id_seq RESTART WITH 1;

INSERT INTO main.contacts
(
    name,
    tags
)
VALUES (
    'user 1',
    main.get_and_maybe_insert_contact_tags(ARRAY['tag1', 'tag2', 'tag3'])
);

SELECT results_eq(
    $$
        SELECT name, tags FROM main.contacts ORDER BY name;
    $$,
    $$
        VALUES
            ('user 1'::VARCHAR, '{1,2,3}'::INTEGER[])
    $$
);

SELECT results_eq(
    $$
        SELECT id, name, contact_counts FROM main.contact_tags ORDER BY id;
    $$,
    $$
        VALUES
            (1, 'tag1', 1),
            (2, 'tag2', 1),
            (3, 'tag3', 1)
    $$
);

INSERT INTO main.contacts
(
    name,
    tags
)
VALUES (
    'user 2',
    main.get_and_maybe_insert_contact_tags(ARRAY['tag1', 'tag4', 'tag5'])
);

SELECT results_eq(
    $$
        SELECT name, tags FROM main.contacts ORDER BY name;
    $$,
    $$
        VALUES
            ('user 1'::VARCHAR, '{1,2,3}'::INTEGER[]),
            ('user 2'::VARCHAR, '{1,4,5}'::INTEGER[])
    $$
);

SELECT results_eq(
    $$
        SELECT id, name, contact_counts FROM main.contact_tags ORDER BY id;
    $$,
    $$
        VALUES
            (1, 'tag1', 2),
            (2, 'tag2', 1),
            (3, 'tag3', 1),
            (4, 'tag4', 1),
            (5, 'tag5', 1)
    $$
);

UPDATE main.contacts
SET
    tags = (main.get_and_maybe_insert_contact_tags(ARRAY['tag4', 'tag5', 'tag6']))
WHERE
    name = 'user 2';

SELECT results_eq(
    $$
        SELECT id, name, contact_counts FROM main.contact_tags ORDER BY id;
    $$,
    $$
        VALUES
            (1, 'tag1', 1),
            (2, 'tag2', 1),
            (3, 'tag3', 1),
            (4, 'tag4', 1),
            (5, 'tag5', 1),
            (6, 'tag6', 1)
    $$
);

ROLLBACK;
