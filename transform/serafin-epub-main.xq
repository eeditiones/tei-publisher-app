import module namespace m='http://www.tei-c.org/pm/models/serafin/epub' at '/db/apps/tei-publisher/transform/serafin-epub.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/serafin.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)