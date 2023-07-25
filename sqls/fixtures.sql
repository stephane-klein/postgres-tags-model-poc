\echo "Cleaning tables..."

SET client_min_messages TO WARNING;

TRUNCATE public.contacts;
TRUNCATE public.contact_tags;

\echo "Tables cleaned"

\echo "Generate fixtures..."

INSERT INTO public.contacts
(
    name,
    tags
)
VALUES (
    'User1',
    get_and_maybe_insert_contact_tags(ARRAY['tag1', 'tag2'])
);

INSERT INTO public.contacts
(
    name,
    tags
)
VALUES (
    'User2',
    get_and_maybe_insert_contact_tags(ARRAY['tag2', 'tag3'])
);

INSERT INTO public.contacts
(
    name,
    tags
)
VALUES (
    'User3',
    get_and_maybe_insert_contact_tags(ARRAY['tag4', 'tag5'])
);

INSERT INTO public.contacts
(
    name,
    tags
)
VALUES (
    'User4',
    null
);

\echo "Fixtures generated"
