import module namespace m='http://www.tei-c.org/tei-simple/models/teisimple.odd' at '/db/apps/tei-simple/transform/teisimple-latex.xql';

declare variable $xml external;

let $options := map {
    "image-dir": (system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-0.3/test/", system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-0.3/doc/"),
    "styles": ["../transform/teisimple.css"],
    "collection": "/db/apps/tei-simple/transform"
}
return m:transform($options, $xml)