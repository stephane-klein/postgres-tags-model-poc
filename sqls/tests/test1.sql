BEGIN;
SELECT plan(4);

SELECT has_table('main'::name, 'contacts'::name);
SELECT has_table('main'::name, 'contact_tags'::name);

DELETE FROM main.contacts CASCADE;
DELETE FROM main.contact_tags CASCADE;
ALTER SEQUENCE main.contact_tags_id_seq RESTART WITH 1;

SELECT main.insert_contact(
    _name => 'user 1',
    tags => ARRAY['tag1', 'tag2', 'tag3']
);

SELECT * FROM main.contact_tags;

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

ROLLBACK;
