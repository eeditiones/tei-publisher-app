import module namespace m='http://www.tei-c.org/pm/models/ukraina/fo' at '/db/apps/tei-publisher/transform/ukraina-fo.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/ukraina.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)