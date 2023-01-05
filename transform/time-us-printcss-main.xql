import module namespace m='http://www.tei-c.org/pm/models/time-us/printcss' at '/db/apps/tei-publisher/transform/time-us-printcss.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/time-us.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)