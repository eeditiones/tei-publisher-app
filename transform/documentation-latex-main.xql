import module namespace m='http://www.tei-c.org/tei-simple/models/documentation.odd/latex' at '/db/apps/tei-simple/transform/documentation-latex.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "image-dir": (system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-1.0/test/", system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-1.0/doc/"),
    "styles": ["../transform/documentation.css"],
    "collection": "/db/apps/tei-simple/transform",
    "parameters": $parameters
}
return m:transform($options, $xml)