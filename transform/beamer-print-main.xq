import module namespace m='http://www.tei-c.org/pm/models/beamer/fo' at '/db/apps/tei-publisher/transform/beamer-print.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["../transform/beamer.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)