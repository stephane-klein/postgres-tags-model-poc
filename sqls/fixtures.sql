\echo "Cleaning tables..."

SET client_min_messages TO WARNING;

TRUNCATE public.contacts;
TRUNCATE public.contact_tags;

\echo "Tables cleaned"

\echo "Generate fixtures..."

SELECT public.insert_contact(
    _name => 'Stéphane',
    tags => ARRAY['Montrouge', 'Pongiste']
);

SELECT public.insert_contact(
    _name => 'Sarah',
    tags => ARRAY['Montrouge', 'Flamenco']
);

\echo "Fixtures generated"
