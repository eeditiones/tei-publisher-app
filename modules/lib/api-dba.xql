xquery version "3.1";

declare namespace api="https://tei-publisher.com/xquery/api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://e-editiones.org/roaster";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace dapi="http://teipublisher.com/api/documents" at "api/document.xql";
import module namespace vapi="http://teipublisher.com/api/view" at "api/view.xql";

(:~
 : This module runs with dba group privileges (setgid), which are required to
 : call pdflatex. To avoid exposing other endpoints with elevated rights, the
 : lookup only resolves the LaTeX operation and its error handler.
 :)
declare variable $local:allowed := ("dapi:latex", "vapi:handle-error");

let $lookup := function($name as xs:string) {
    if ($name = $local:allowed) then
        try {
            function-lookup(xs:QName($name), 1)
        } catch * {
            ()
        }
    else
        ()
}
let $resp := router:route("modules/lib/api.json", $lookup)
return
    $resp