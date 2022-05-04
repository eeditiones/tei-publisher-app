import module namespace m='http://www.tei-c.org/pm/models/teipublisher_odds/latex' at '/db/apps/tei-publisher/transform/teipublisher_odds-latex.xqm';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "class": "article",
    "section-numbers": false(),
    "font-size": "11pt",
    "styles": ["transform/teipublisher_odds.css"],
    "collection": "/db/apps/tei-publisher/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)