module namespace pml='http://www.tei-c.org/tei-simple/models/documentation.odd/module';

import module namespace m='http://www.tei-c.org/tei-simple/models/documentation.odd' at '/db/apps/tei-simple/transform/documentation-latex.xql';

(: Generated library module to be directly imported into code which
 : needs to transform TEI nodes using the ODD this module is based on.
 :)
declare function pml:transform($xml as node()*, $parameters as map(*)?) {

   let $options := map {
    "image-dir": (system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-0.6/test/", system:get-exist-home() || "/webapp/WEB-INF/data/expathrepo/tei-simple-0.6/doc/"),
       "styles": ["../transform/documentation.css"],
       "collection": "/db/apps/tei-simple/transform",
       "parameters": $parameters
   }
   return m:transform($options, $xml)
};