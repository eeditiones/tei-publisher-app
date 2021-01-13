import module namespace m='http://www.tei-c.org/pm/models/serafin/web' at '/db/apps/tei-publisher/transform/serafin-web.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/serafin.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)