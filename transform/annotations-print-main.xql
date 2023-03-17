import module namespace m='http://www.tei-c.org/pm/models/annotations/print' at '/db/apps/tei-publisher/transform/annotations-print.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/annotations.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)