import module namespace m='http://www.tei-c.org/pm/models/dantiscus2/latex' at '/db/apps/tei-publisher/transform/dantiscus2-latex.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "class": "article",
    "section-numbers": false(),
    "font-size": "11pt",
    "styles": ["transform/dantiscus2.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)