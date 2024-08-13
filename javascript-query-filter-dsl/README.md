# Query search parser to sql

This Javascript query search parser based [Peggy](https://peggyjs.org/), converts a string like `Tag1 or (Tag2 and Tag3)` into an SQL query: 

```sql
'Tag1' = ANY (tags) OR ('Tag2' = ANY (tags) AND 'Tag3' = ANY (tags)')'
```

More examples available in the [`plaground.js`](./plaground.js) file.
 

```sh
$ mise install
$ pnpm install
$ pnpm run peggy
$ ./playground.js
input: Tag2
SELECT * FROM article WHERE 'Tag2' = ANY (tags);
input:  Tag2 and Tag3
SELECT * FROM article WHERE 'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags);
input: (Tag2 and Tag3)
SELECT * FROM article WHERE (
  'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags)
);
input: (Tag2 and Tag3) or Tag8
SELECT * FROM article WHERE (
  'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags)
) OR 'Tag8' = ANY (tags);
input: Tag1 or (Tag2 and Tag3)
SELECT * FROM article WHERE 'Tag1' = ANY (tags) OR (
  'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags)
);
input: Tag1 or (Tag2 and Tag3 or tag8)
SELECT * FROM article WHERE 'Tag1' = ANY (tags) OR (
  'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags) OR 'tag8' = ANY (tags)
);
input: not Tag2
SELECT * FROM article WHERE NOT( 'Tag2' = ANY (tags) );
input: Tag1 or not (Tag2 and Tag3)
SELECT * FROM article WHERE 'Tag1' = ANY (tags) OR NOT( (
  'Tag2' = ANY (tags) AND 'Tag3' = ANY (tags)
) );
```

The following command can be used during the development phase:

```sh
$ pnpm run peggy -t "Tag1 or (Tag2 and Tag3)" -w

> javascript-query-filter-dsl@1.0.0 peggy /home/stephane/git/github.com/stephane-klein/postgres-tags-model-poc/javascript-query-filter-dsl
> peggy --format es -o query-filter.js query-filter.peggy "-t" "Tag1 or (Tag2 and Tag3)" "-w"

"/home/stephane/git/github.com/stephane-klein/postgres-tags-model-poc/javascript-query-filter-dsl/query-filter.peggy" changed...
"'Tag1' = ANY (undefined) OR (\n" +
  "  'Tag2' = ANY (undefined) AND 'Tag3' = ANY (undefined)\n" +
  ')'
```

More information, see https://peggyjs.org/documentation.html#generating-a-parser-command-line
