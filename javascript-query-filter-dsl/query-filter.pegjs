/*
associative "associative"
  = "(" _ expression _ ")" { return text(); }
  / expression { return text(); }
*/

expression "expression"
  = head:term tail:(_ ("or" / "and") _ term)* {
      return tail.reduce(function(result, element) {
            if (element[1] === "or") { return result + " or " + element[3]; }
            if (element[1] === "and") { return result + " and " + element[3]; }
      }, head);
  }

term "term"
  = head:factor tail:(_ ("or" / "and") _ factor)* {
      return tail.reduce(function(result, element) {
            if (element[1] === "or") { return result + " or " + element[3]; }
            if (element[1] === "and") { return result + " and " + element[3]; }
      }, head);
  }

factor
  = ("(" _ @expression _ ")")
  / tagname

tagname "tagname"
  = _ [a-z]i[0-9a-z]i* _ { return text(); }

_ "whitespace"
  = [ \t\n\r]*
