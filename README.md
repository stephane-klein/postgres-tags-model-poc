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
```
