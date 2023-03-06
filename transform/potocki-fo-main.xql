import module namespace m='http://www.tei-c.org/pm/models/potocki/fo' at '/db/apps/tei-publisher/transform/potocki-fo.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/potocki.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)