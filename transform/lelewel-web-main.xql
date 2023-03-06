import module namespace m='http://www.tei-c.org/pm/models/lelewel/web' at '/db/apps/tei-publisher/transform/lelewel-web.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/lelewel.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)