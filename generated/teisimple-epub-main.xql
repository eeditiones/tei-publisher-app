import module namespace m='http://www.tei-c.org/tei-simple/models/teisimple.odd' at '/db/apps/tei-simple/generated/teisimple-epub.xql';

declare variable $xml external;

let $options := map {
   "styles": ["../resources/odd/teisimple.css"],
   "collection": "/db/apps/tei-simple/generated"
}
return m:transform($options, $xml)