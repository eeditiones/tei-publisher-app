module namespace pml='http://www.tei-c.org/tei-simple/models/myteisimple.odd/module';

import module namespace m='http://www.tei-c.org/tei-simple/models/myteisimple.odd' at '/db/apps/tei-simple/transform/myteisimple-web.xql';

(: Generated library module to be directly imported into code which
 : needs to transform TEI nodes using the ODD this module is based on.
 :)
declare function pml:transform($xml as node()*, $parameters as map(*)?) {

   let $options := map {
       "styles": ["../transform/myteisimple.css"],
       "collection": "/db/apps/tei-simple/transform",
       "parameters": $parameters
   }
   return m:transform($options, $xml)
};