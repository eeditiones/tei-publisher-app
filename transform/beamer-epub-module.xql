module namespace pml='http://www.tei-c.org/tei-simple/models/beamer.odd/module';

import module namespace m='http://www.tei-c.org/tei-simple/models/beamer.odd' at '/db/apps/tei-simple/transform/beamer-epub.xql';

(: Generated library module to be directly imported into code which
 : needs to transform TEI nodes using the ODD this module is based on.
 :)
declare function pml:transform($xml as node()*, $parameters as map(*)?) {

   let $options := map {
       "styles": ["../transform/beamer.css"],
       "collection": "/db/apps/tei-simple/transform",
       "parameters": $parameters
   }
   return m:transform($options, $xml)
};