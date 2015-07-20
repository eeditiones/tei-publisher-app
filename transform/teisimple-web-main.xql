import module namespace m='http://www.tei-c.org/tei-simple/models/teisimple.odd' at '/db/apps/tei-simple/transform/teisimple-web.xql';

declare variable $xml external;

let $options := map {
    "styles": ["../transform/teisimple.css"],
    "collection": "/db/apps/tei-simple/transform"
}
return m:transform($options, $xml)