xquery version "3.1";

module namespace capi="http://teipublisher.com/api/collection";

import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "../browse.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../pages.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace docx="http://existsolutions.com/teipublisher/docx";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace custom="http://teipublisher.com/api/custom" at "../../custom-api.xql";

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
    let $lookup := function($name as xs:string, $arity as xs:integer) {
        try {
            (
                custom:lookup($name, $arity),
                error(err:XPST0081)
            )[1]
        } catch err:XPST0081 {
            function-lookup(xs:QName($name), $arity)
        }
    }
    return
        templates:apply(doc($template), $lookup, map { "root": $path }, $config)
};

declare function capi:upload($request as map(*)) {
    let $name := request:get-uploaded-file-name("files[]")
    let $data := request:get-uploaded-file-data("files[]")
    return
        array { capi:upload($request?parameters?collection, $name, $data) }
};

declare %private function capi:upload($root, $paths, $payloads) {
    for-each-pair($paths, $payloads, function($path, $data) {
        let $path :=
            if (ends-with($path, ".odd")) then
                xmldb:store($config:odd-root, xmldb:encode($path), $data)
            else
                let $collectionPath := $config:data-root || "/" || $root
                return
                    if (xmldb:collection-available($collectionPath)) then
                        if (ends-with($path, ".docx")) then
                            let $mediaPath := $config:data-root || "/" || $root || "/" || xmldb:encode($path) || ".media"
                            let $stored := xmldb:store($collectionPath, xmldb:encode($path), $data)
                            let $tei :=
                                docx:process($stored, $config:data-root, $pm-config:tei-transform(?, ?, "docx.odd"), $mediaPath)
                            let $teiDoc :=
                                document {
                                    processing-instruction teipublisher {
                                        $config:default-docx-pi
                                    },
                                    $tei
                                }
                            return
                                xmldb:store($collectionPath, xmldb:encode($path) || ".xml", $teiDoc)
                        else
                            xmldb:store($collectionPath, xmldb:encode($path), $data)
                    else
                        error($errors:NOT_FOUND, "Collection not found: " || $collectionPath)
        return
            map {
                "name": $path,
                "path": substring-after($path, $config:data-root || "/" || $root),
                "type": xmldb:get-mime-type($path),
                "size": 93928
            }
    })
};