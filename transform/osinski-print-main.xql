import module namespace m='http://www.tei-c.org/pm/models/osinski/print' at '/db/apps/tei-publisher/transform/osinski-print.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/osinski.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)