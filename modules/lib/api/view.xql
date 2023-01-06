xquery version "3.1";

module namespace vapi="http://teipublisher.com/api/view";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib" at "../templates-lib.xql";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "../browse.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../pages.xql";
import module namespace custom="http://teipublisher.com/api/custom" at "../../custom-api.xql";

(:
: We have to provide a lookup function to templates:apply to help it
: find functions in the imported application modules. The templates
: module cannot see the application modules, but the inline function
: below does see them.
:)
declare function vapi:lookup($name as xs:string, $arity as xs:int) {
    try {
        let $cfun := custom:lookup($name, $arity)
        return
            if (empty($cfun)) then
                function-lookup(xs:QName($name), $arity)
            else
                $cfun
    } catch * {
        ()
    }
};

declare function vapi:get-template($config as map(*), $template as xs:string?) {
    if ($template) then
        $template
    else
        $config?template
};

declare function vapi:get-config($doc as xs:string, $view as xs:string?) {
    let $document := config:get-document($doc)
    return
        if (exists($document)) then
            tpu:parse-pi(root($document), $view)
        else
            error($errors:NOT_FOUND, "document " || $doc || " not found")
};

declare function vapi:view($request as map(*)) {
    let $path :=
        if ($request?parameters?suffix) then 
            xmldb:decode($request?parameters?docid) || $request?parameters?suffix
        else
            xmldb:decode($request?parameters?docid)
    let $config := vapi:get-config($path, $request?parameters?view)
    let $templateName := head((vapi:get-template($config, $request?parameters?template), $config:default-template))
    let $templatePaths := ($config:app-root || "/templates/pages/" || $templateName, $config:app-root || "/templates/" || $templateName)
    let $template :=
        for-each($templatePaths, function($path) {
            if (doc-available($path)) then
                doc($path)
            else
                ()
        }) => head()
    return
        if (not($template)) then
            error($errors:NOT_FOUND, "template " || $templateName || " not found")
        else
            let $model := map { 
                "doc": $path,
                "template": $templateName,
                "media": if (map:contains($config, 'media')) then $config?media else ()
            }
            return
                templates:apply($template, vapi:lookup#2, $model, tpu:get-template-config($request))
};

declare function vapi:html($request as map(*)) {
    let $path := $config:app-root || "/templates/" || xmldb:decode($request?parameters?file) || ".html"
    let $template :=
        if (doc-available($path)) then
            doc($path)
        else
            error($errors:NOT_FOUND, "HTML file " || $path || " not found")
    return
        templates:apply($template, vapi:lookup#2, (), tpu:get-template-config($request))
};

declare function vapi:handle-error($error) {
    let $path := $config:app-root || "/templates/error-page.html"
    let $template := doc($path)
    return
        templates:apply($template, vapi:lookup#2, map { "description": $error?description }, $tpu:template-config)
};