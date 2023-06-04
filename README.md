Database model POC based on [Tags and Postgres Arrays, a Purrrfect Combination](https://www.crunchydata.com/blog/tags-aand-postgres-arrays-a-purrfect-combination) article.

```sh
$ docker compose up -d --wait
```

```
$ ./scripts/seed.sh
$ ./scripts/fixtures.sh
```

```
$ ./scripts/enter-in-pg.sh
postgres=# SELECT
    contacts.id,
    contacts.name,
    array_agg(contact_tags.name)
FROM
    public.contacts
CROSS JOIN UNNEST(contacts.tags) AS tag_id
JOIN public.contact_tags
ON contact_tags.id = tag_id
GROUP BY
    contacts.id,
    contacts.name;
                  id                  | name  |  array_agg
--------------------------------------+-------+-------------
 80918d5a-92dc-4ddf-ad46-f61060831c95 | User3 | {tag4,tag5}
 18f6dca3-1196-4e00-809c-cf19efdb3994 | User2 | {tag2,tag3}
 678f9c32-f410-4c45-9255-43463189e80d | User1 | {tag1,tag2}
(3 rows)
```
