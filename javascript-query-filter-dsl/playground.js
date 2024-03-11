#!/usr/bin/env node

import { parse } from "./query-filter.js";

console.log(parse("Tag2 and Tag3"));
console.log(parse("(Tag2 and Tag3)"));
console.log(parse("(Tag2 and Tag3) or Tag8"));
console.log(parse("Tag1 or (Tag2 and Tag3)"));
console.log(parse("Tag1 or (Tag2 and Tag3 or tag8)"));
