BEGIN;
SELECT plan(2);

SELECT has_table('main'::name, 'contacts'::name);
SELECT has_table('main'::name, 'contact_tags'::name);

DELETE FROM main.contacts CASCADE;

SELECT main.insert_contact(
    _name => 'user 1',
    tags => ARRAY['tag1', 'tag2', 'tag3']
);

SELECT * FROM main.contacts;

SELECT * FROM main.contact_tags;

ROLLBACK;
