import module namespace m='http://www.tei-c.org/tei-simple/models/myteisimple.odd' at '/db/apps/tei-simple/transform/myteisimple-web.xql';

declare variable $xml external;

let $options := map {
    "styles": ["../transform/myteisimple.css"],
    "collection": "/db/apps/tei-simple/transform"
}
return m:transform($options, $xml)