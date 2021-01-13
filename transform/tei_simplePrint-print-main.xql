import module namespace m='http://www.tei-c.org/pm/models/tei_simplePrint/fo' at '/db/apps/tei-publisher/transform/tei_simplePrint-print.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/tei_simplePrint.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)