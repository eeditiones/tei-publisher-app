xquery version "3.1";

module namespace capi="http://teipublisher.com/api/collection";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "../browse.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../pages.xql";
import module namespace templates="http://exist-db.org/xquery/templates";

declare function capi:list($request as map(*)) {
    let $path := if ($request?parameters?path) then xmldb:decode($request?parameters?path) else ()
    let $templatePath := $config:data-root || "/" || $path || "/collection.html"
    let $templateAvail := doc-available($templatePath) or util:binary-doc-available($templatePath)
    let $template := 
        if ($templateAvail) then 
            $templatePath
        else
            $config:app-root || "/templates/documents.html"
    let $config := map {
        $templates:CONFIG_APP_ROOT : $config:app-root,
        $templates:CONFIG_STOP_ON_ERROR : true()
    }
    let $lookup := function($functionName as xs:string, $arity as xs:int) {
        try {
            function-lookup(xs:QName($functionName), $arity)
        } catch * {
            ()
        }
    }
    return
        templates:apply(doc($template), $lookup, map { "root": $path }, $config)
};