import module namespace m='http://www.tei-c.org/pm/models/beamer/latex' at '/db/apps/tei-publisher/transform/beamer-latex.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "class": "article",
    "section-numbers": false(),
    "font-size": "12pt",
    "styles": ["../transform/beamer.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)