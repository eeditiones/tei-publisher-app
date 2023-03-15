import module namespace m='http://www.tei-c.org/pm/models/adagia/web' at '/db/apps/tei-publisher/transform/adagia-web.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/adagia.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)