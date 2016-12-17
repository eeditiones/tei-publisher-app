module namespace pml='http://www.tei-c.org/pm/models/beamer/latex/module';

import module namespace m='http://www.tei-c.org/pm/models/beamer/latex' at '/db/apps/tei-publisher/transform/beamer-latex.xql';

(: Generated library module to be directly imported into code which
 : needs to transform TEI nodes using the ODD this module is based on.
 :)
declare function pml:transform($xml as node()*, $parameters as map(*)?) {

   let $options := map {
    "class": "article",
    "section-numbers": false(),
    "font-size": "12pt",
       "styles": ["../transform/beamer.css"],
       "collection": "/db/apps/tei-publisher/transform",
       "parameters": if (exists($parameters)) then $parameters else map {}
   }
   return m:transform($options, $xml)
};