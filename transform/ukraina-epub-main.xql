import module namespace m='http://www.tei-c.org/pm/models/ukraina/epub' at '/db/apps/tei-publisher/transform/ukraina-epub.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/ukraina.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)