\echo "Cleaning tables..."

SET client_min_messages TO WARNING;

TRUNCATE public.contacts;
TRUNCATE public.contact_tags;

\echo "Tables cleaned"

\echo "Generate fixtures..."

SELECT public.insert_contact(
    _name => 'User1',
    tags => ARRAY['tag1', 'tag2']
);

SELECT public.insert_contact(
    _name => 'User2',
    tags => ARRAY['tag2', 'tag3']
);

SELECT public.insert_contact(
    _name => 'User3',
    tags => ARRAY['tag4', 'tag5']
);

SELECT public.insert_contact(
    _name => 'User4',
    tags => null
);

\echo "Fixtures generated"
