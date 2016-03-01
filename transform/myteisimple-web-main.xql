import module namespace m='http://www.tei-c.org/tei-simple/models/myteisimple.odd/web' at '/db/apps/tei-simple/transform/myteisimple-web.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["../transform/myteisimple.css"],
    "collection": "/db/apps/tei-simple/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)