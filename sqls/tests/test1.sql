BEGIN;
SELECT plan(2);

SELECT has_table('main'::name, 'contacts'::name);
SELECT has_table('main'::name, 'contact_tags'::name);

ROLLBACK;
