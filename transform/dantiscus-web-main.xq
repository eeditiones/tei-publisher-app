import module namespace m='http://www.tei-c.org/pm/models/dantiscus/web' at '/db/apps/tei-publisher/transform/dantiscus-web.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["transform/dantiscus.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)