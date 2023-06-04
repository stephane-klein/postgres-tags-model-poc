Database model POC based on [Tags and Postgres Arrays, a Purrrfect Combination](https://www.crunchydata.com/blog/tags-aand-postgres-arrays-a-purrfect-combination) article.

```sh
$ docker compose up -d --wait
```

```
$ ./scripts/seed.sh
$ ./scripts/fixtures.sh
```

```
postgres=# WITH exploded AS (
     SELECT
         contacts.id,
         tag_id
     FROM
         public.contacts
     CROSS JOIN UNNEST(contacts.tags) AS tag_id
 )
 SELECT
     contacts.id,
     contacts.name,
     ARRAY_AGG(contact_tags.name) AS tag_names
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
     contacts.id,
     contacts.name;
+--------------------------------------+-------+------------------+
| id                                   | name  | tag_names        |
|--------------------------------------+-------+------------------|
| 1673cde1-534b-4517-b918-222ed7b3845f | User4 | [None]           |
| 80918d5a-92dc-4ddf-ad46-f61060831c95 | User3 | ['tag4', 'tag5'] |
| 18f6dca3-1196-4e00-809c-cf19efdb3994 | User2 | ['tag2', 'tag3'] |
| 678f9c32-f410-4c45-9255-43463189e80d | User1 | ['tag1', 'tag2'] |
+--------------------------------------+-------+------------------+
```

```
postgres=# WITH exploded AS (
     SELECT
         contacts.id,
         tag_id
     FROM
         public.contacts
     CROSS JOIN UNNEST(contacts.tags) AS tag_id
 )
 SELECT
     contacts.id,
     contacts.name,
     JSON_AGG(
          json_build_object(
             'id',
             contact_tags.id,
             'name',
             contact_tags.name
         )
     ) AS tags
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
     contacts.id,
     contacts.name;
+--------------------------------------+-------+-------------------------------------------------------------+
| id                                   | name  | tags                                                        |
|--------------------------------------+-------+-------------------------------------------------------------|
| 1673cde1-534b-4517-b918-222ed7b3845f | User4 | [{"id" : null, "name" : null}]                              |
| 80918d5a-92dc-4ddf-ad46-f61060831c95 | User3 | [{"id" : 9, "name" : "tag4"}, {"id" : 10, "name" : "tag5"}] |
| 18f6dca3-1196-4e00-809c-cf19efdb3994 | User2 | [{"id" : 7, "name" : "tag2"}, {"id" : 8, "name" : "tag3"}]  |
| 678f9c32-f410-4c45-9255-43463189e80d | User1 | [{"id" : 6, "name" : "tag1"}, {"id" : 7, "name" : "tag2"}]  |
+--------------------------------------+-------+-------------------------------------------------------------+
SELECT 4
Time: 0.006s
```

Insert new contact with 3 tags:

```
SELECT public.insert_contact(
    _name => 'User5',
    tags => ARRAY['tag4', 'tag5', 'tag6']
);
```

If you feel like it, you can use [pgcli](https://github.com/dbcli/pgcli) to experiment:

```sh
$ pip install -U pgcli
```

```
$ ./scripts/pgcli.sh
Server: PostgreSQL 15.2 (Debian 15.2-1.pgdg110+1)
Version: 3.5.0
Home: http://pgcli.com
postgres@127:postgres>
```
