import module namespace m='http://www.tei-c.org/tei-simple/models/teisimple.odd' at '/db/apps/tei-simple/generated/teisimple.xql';

declare variable $xml external;

let $options := map {
   "styles": ["../generated/teisimple.css"]
}
return m:transform($options, $xml)