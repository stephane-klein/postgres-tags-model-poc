expression =
  head:bloc
  tail:(op:operator bloc) *
  {
    //console.log("tail", tail, "head", head);
    return tail.reduce((result, element) => {
      //console.log("debug", element);
      return `${result} ${element[0]} ${element[1]}`;
    }, head);
  }

parenthesis =
  begin_parenthesis content:(parenthesis / expression ) end_parenthesis
  {
    return `(\n  ${content}\n)`;
  }

tagname "tagname"
  = ws [a-zA-Z][_0-9a-zA-Z]* ws { return `'${text()}' = ANY (${options.column}) `; }

begin_parenthesis = ws "(" ws   { return "(";   }
end_parenthesis   = ws ")" ws   { return ")";   }
and               = ws "and" ws { return "AND"; }
or                = ws "or"  ws { return "OR";  }
operator          = and / or

ws "whitespace"
  = [ \t\n\r]*

bloc = tagname / parenthesis
