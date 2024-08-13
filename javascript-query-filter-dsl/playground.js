#!/usr/bin/env node

import { parse } from "./query-filter.js";

class Parse {

    constructor(table, column) {
        this.table = table;
        this.column = column;
    }

    parse(txt) {
        console.log("input:", txt);
        const raw = parse(txt, {column : this.column});
        return `SELECT * FROM ${this.table} WHERE ${raw};`;
    }
}

let p = new Parse('article', 'tags');

console.log(p.parse("Tag2"));
console.log(p.parse(" Tag2 and Tag3"));
console.log(p.parse("(Tag2 and Tag3)"));
console.log(p.parse("(Tag2 and Tag3) or Tag8"));
console.log(p.parse("Tag1 or (Tag2 and Tag3)"));
console.log(p.parse("Tag1 or (Tag2 and Tag3 or tag8)"));

console.log(p.parse("not Tag2"));
console.log(p.parse("Tag1 or not (Tag2 and Tag3)"));
