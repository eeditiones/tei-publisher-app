import module namespace m='http://www.tei-c.org/tei-simple/models/documentation.odd' at '/db/apps/tei-simple/transform/documentation-epub.xql';

declare variable $xml external;

let $options := map {
    "styles": ["../transform/documentation.css"],
    "collection": "/db/apps/tei-simple/transform"
}
return m:transform($options, $xml)