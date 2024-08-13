expression =
  head:bloc
  tail:(op:operator ws bloc) *
  {
    return tail.reduce((result, element) => {
      return `${result} ${element[0]} ${element[2]}`;
    }, head);
  };

not =
  "not" ws b:bloc
  {
    return `NOT( ${b} )`;
  };

parenthesis =
  begin_parenthesis content:(parenthesis / expression ) end_parenthesis
  {
    return `(\n  ${content}\n)`;
  };

tagname
  = ws head:[a-zA-Z] tail:[_0-9a-zA-Z]* ws { return `'${head}${tail.join("")}' = ANY (${options.column})`};

begin_parenthesis = ws "(" ws   { return "(";   };
end_parenthesis   = ws ")" ws   { return ")";   };
and               = ws "and" ws { return "AND"; };
or                = ws "or"  ws { return "OR";  };
operator          = and / or;

ws
  = [ \t\n\r]*;

bloc = not / tagname / parenthesis;
