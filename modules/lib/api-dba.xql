xquery version "3.1";

declare namespace api="https://tei-publisher.com/xquery/api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router";
import module namespace rutil="http://exist-db.org/xquery/router/util";
import module namespace dapi="http://teipublisher.com/api/documents" at "api/document.xql";
import module namespace vapi="http://teipublisher.com/api/view" at "api/view.xql";
import module namespace deploy="http://teipublisher.com/api/generate" at "api/generate.xql";
import module namespace nlp="http://teipublisher.com/api/nlp" at "api/nlp.xql";

let $lookup := function($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
}
let $resp := router:route("modules/lib/api.json", $lookup)
return
    $resp