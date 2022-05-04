import module namespace m='http://www.tei-c.org/pm/models/annotations/fo' at '/db/apps/tei-publisher/transform/annotations-print.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/annotations.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)