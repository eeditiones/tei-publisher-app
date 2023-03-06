import module namespace m='http://www.tei-c.org/pm/models/ebbe/web' at '/db/apps/tei-publisher/transform/ebbe-web.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/ebbe.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)