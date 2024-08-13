```sh
$ mise install
$ pnpm install
$ pnpm run peggy
$ ./playground.js
Tag2  and Tag3
Tag2  and Tag3
Tag2  and Tag3 or Tag8
Tag1  or Tag2  and Tag3
Tag1  or Tag2  and Tag3  or tag8
```

The following command can be used during the development phase:

```sh
$ pnpm run peggy -t " Tag2 and Tag3" -w

> javascript-query-filter-dsl@1.0.0 peggy /home/stephane/git/github.com/stephane-klein/postgres-tags-model-poc/javascript-query-filter-dsl
> peggy --format es -o query-filter.js query-filter.pegjs "-t" " Tag2 and Tag3"

"'Ta,g,2' = ANY (undefined)  AND 'Ta,g,3' = ANY (undefined) "
```

More information, see https://peggyjs.org/documentation.html#generating-a-parser-command-line
