Database model POC based on [Tags and Postgres Arrays, a Purrrfect Combination](https://www.crunchydata.com/blog/tags-aand-postgres-arrays-a-purrfect-combination) article.

The [`query-string-js-parser/`](./query-string-js-parser/) folder contains a Javascript parser that converts a string query into sql.

```sh
$ docker compose up -d --wait
```

```
$ ./scripts/seed.sh
$ ./scripts/fixtures.sh
```

Enter in Postgres:
```
./scripts/enter-in-pg.sh
postgres=#
```

Retrieves all contacts with their associated tag names.

```sql
postgres=# SELECT * FROM main.contacts_with_tag_names;
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| 0c6f17dd-03a3-484d-b4fb-619fcd9cd4f7 | User1 | [1, 2] | ['tag1', 'tag2'] |
| a270741b-6a1a-4a2f-a847-eb37c522f596 | User2 | [2, 3] | ['tag2', 'tag3'] |
| 019d3463-6294-4f30-af96-f3e8d698cd1d | User4 | <null> | [None]           |
| 18a86616-a1f5-41b2-89ff-4dd51d132e58 | User3 | [4, 5] | ['tag4', 'tag5'] |
+--------------------------------------+-------+--------+------------------+
```

Retrieves all contacts with the id and name of their associated tags in json format.

```sql
postgres=# SELECT * FROM main.contacts_with_tags;
+--------------------------------------+-------+--------+------------------------------------------------------------+
| id                                   | name  | tags   | json_agg                                                   |
|--------------------------------------+-------+--------+------------------------------------------------------------|
| 4f026b11-e7c5-4143-b9f6-4105f79e17ee | User4 | <null> | [{"id" : null, "name" : null}]                             |
| ae497426-f391-403b-a902-871f35fada89 | User1 | [1, 2] | [{"id" : 1, "name" : "tag1"}, {"id" : 2, "name" : "tag2"}] |
| 343315b7-94b3-4ef3-975a-da49005b29b8 | User3 | [4, 5] | [{"id" : 4, "name" : "tag4"}, {"id" : 5, "name" : "tag5"}] |
| 433bf6b7-3c9c-4035-b61c-57dc77a15862 | User2 | [2, 3] | [{"id" : 2, "name" : "tag2"}, {"id" : 3, "name" : "tag3"}] |
+--------------------------------------+-------+--------+------------------------------------------------------------+
```

Insert new contact with 3 tags:

```sql
INSERT INTO main.contacts
(
    name,
    tags
)
VALUES (
    'User1',
    main.get_and_maybe_insert_contact_tags(ARRAY['tag4', 'tag5', 'tag6'])
);
```

Update contact tags:

```sql
UPDATE main.contacts
SET
    tags = (main.get_and_maybe_insert_contact_tags(ARRAY['tag6', 'tag7']))
WHERE
    name = 'User5';
```

Fetch all tags and the number of contacts associated with each:

```sql
SELECT
    contact_tags.name,
    COUNT(contacts.id) AS contact_count
FROM
    main.contact_tags
LEFT JOIN
    main.contacts
ON
    contact_tags.id = ANY(contacts.tags)
GROUP BY contact_tags.id;
+------+---------------+
| name | contact_count |
|------+---------------|
| tag1 | 1             |
| tag2 | 2             |
| tag3 | 1             |
| tag4 | 1             |
| tag5 | 1             |
+------+---------------+
```

List all contact associated with id `2`:

```sql
postgres=# SELECT * FROM main.contacts_with_tag_names WHERE 2 = ANY(tags);
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| 92696bf1-7285-4ec0-bf90-39653d53a2d0 | User2 | [2, 3] | ['tag2', 'tag3'] |
| a155c3b6-15b4-4f93-8ca8-9fc0634069af | User1 | [1, 2] | ['tag1', 'tag2'] |
+--------------------------------------+-------+--------+------------------+
SELECT 2
Time: 0.011s
```

List all contact associated with `tag2`:

```
postgres# SELECT * FROM main.contacts_with_tag_names WHERE (SELECT id FROM main.con
 tact_tags WHERE name='tag2') = ANY(tags);
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| 92696bf1-7285-4ec0-bf90-39653d53a2d0 | User2 | [2, 3] | ['tag2', 'tag3'] |
| a155c3b6-15b4-4f93-8ca8-9fc0634069af | User1 | [1, 2] | ['tag1', 'tag2'] |
+--------------------------------------+-------+--------+------------------+
SELECT 2
Time: 0.007s
```

Another query based on [`&&` operator](https://www.postgresql.org/docs/16/functions-array.html):

```
postgres# (
    SELECT *
    FROM main.contacts_with_tag_names
    WHERE (
        tags && (
            SELECT ARRAY_AGG(id) FROM main.contact_tags WHERE name = ANY(ARRAY['tag2'])
        )
    )
);
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| a155c3b6-15b4-4f93-8ca8-9fc0634069af | User1 | [1, 2] | ['tag1', 'tag2'] |
| 92696bf1-7285-4ec0-bf90-39653d53a2d0 | User2 | [2, 3] | ['tag2', 'tag3'] |
+--------------------------------------+-------+--------+------------------+
```

Query to filter contacts which are linked to `tag1` or `tag5`:

```
postgres# (
    SELECT *
    FROM main.contacts_with_tag_names
    WHERE (
        tags && (
            SELECT ARRAY_AGG(id) FROM main.contact_tags WHERE name = ANY(ARRAY['tag1', 'tag5'])
        )
    )
);
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| a155c3b6-15b4-4f93-8ca8-9fc0634069af | User1 | [1, 2] | ['tag1', 'tag2'] |
| 2a64014e-8e60-4959-b333-f385b61124b8 | User3 | [4, 5] | ['tag4', 'tag5'] |
+--------------------------------------+-------+--------+------------------+
SELECT 2
Time: 0.007s
```

Query to filter contacts which are linked to `tag2` and `tag3`, based on [`<@`](https://www.postgresql.org/docs/16/functions-array.html) operator:

```
postgres# (
    SELECT *
    FROM main.contacts_with_tag_names
    WHERE (
        tags <@ (
            SELECT ARRAY_AGG(id) FROM main.contact_tags WHERE name = ANY(ARRAY['tag2', 'tag3'])
        )
    )
);
+--------------------------------------+-------+--------+------------------+
| id                                   | name  | tags   | tag_names        |
|--------------------------------------+-------+--------+------------------|
| 92696bf1-7285-4ec0-bf90-39653d53a2d0 | User2 | [2, 3] | ['tag2', 'tag3'] |
+--------------------------------------+-------+--------+------------------+
SELECT 1
Time: 0.007s
```

Query to filter contacts which are linked to (`tag2` and `tag3`) or `tag1`:

```
postgres# (
    SELECT *
    FROM main.contacts_with_tag_names
    WHERE (
        (
            tags <@ (
                SELECT ARRAY_AGG(id) FROM main.contact_tags WHERE name = ANY(ARRAY['tag2', 'tag3'])
            )
        ) OR (
            tags && (
                SELECT ARRAY_AGG(id) FROM main.contact_tags WHERE name = ANY(ARRAY['tag1'])
            )
        )
    )
);
```


If you feel like it, you can use [pgcli](https://github.com/dbcli/pgcli) to experiment:

```sh
$ pip install -U pgcli
```

```sh
$ ./scripts/pgcli.sh
Server: PostgreSQL 15.2 (Debian 15.2-1.pgdg110+1)
Version: 3.5.0
Home: http://pgcli.com
postgres@127:postgres>
```

Execute pgTAP tests:

```
$ ./scripts/tests.sh
/sqls/tests/test1.sql ..
1..10
ok 1 - Table main.contacts should exist
ok 2 - Table main.contact_tags should exist
ok 3
ok 4
ok 5
ok 6
ok 7
ok 8
ok 9
ok 10
ok
All tests successful.
Files=1, Tests=10,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: PASS
```
