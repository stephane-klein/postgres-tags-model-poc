[`contact_tags_system.sql`](./contact_tags_system.sql) file is generated by [gomplate](https://gomplate.ca/) with [`tags.system.sql.tmpl`](tags.system.sql.tmpl) template and [`config.yaml`](config.yaml) config file.

Instruction to regenrate the `contact_tags_system.sql` file:

```sh
$ asdf install
$ gomplate -c .=config.yaml -f tags_system.sql.tmpl > contact_tags_system.sql
```
