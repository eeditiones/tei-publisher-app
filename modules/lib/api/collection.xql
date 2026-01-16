xquery version "3.1";

module namespace capi="http://teipublisher.com/api/collection";

import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace vapi="http://teipublisher.com/api/view" at "view.xql";
import module namespace docx="http://existsolutions.com/teipublisher/docx";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace router="http://e-editiones.org/roaster";
import module namespace tmpl="http://e-editiones.org/xquery/templates";

declare function capi:list($request as map(*)) {
    let $per-page := $request?parameters?per-page
    let $path := if ($request?parameters?path) then xmldb:decode($request?parameters?path) else ()
    let $params := capi:params2map($path)
    let $cached := session:get-attribute($config:session-prefix || ".works")
    let $useCached := capi:use-cache($params, $cached)
    let $worksAll := capi:list-works($path, if ($useCached) then $cached else (), $params)
    let $total := count($worksAll?all)
    let $start :=
        if ($request?parameters?start > $total) then
            ($total idiv $per-page) * $per-page + 1
        else
            $request?parameters?start
    let $works := subsequence($worksAll?all, $start, $per-page)
    return (
        response:set-header("pb-start", xs:string($start)),
        response:set-header("pb-total", xs:string($total)),
        if ($request?parameters?format = "html") then
            let $templatePath := $config:data-default || "/" || $path || "/collection.html"
            let $templateAvail := doc-available($templatePath) or util:binary-doc-available($templatePath)
            let $path := 
                if ($templateAvail and $worksAll?mode = 'browse') then 
                    $templatePath
                else
                    $config:app-root || "/templates/documents.html"
            let $template :=
                if (doc-available($path)) then
                    doc($path) => serialize()
                else if (util:binary-doc-available($path)) then
                    util:binary-doc($path) => util:binary-to-string()
                else
                    error($errors:NOT_FOUND, "HTML file " || $path || " not found")
            let $model := map:merge((vapi:load-config-json($request), map { "documents": $works, "language": $request?parameters?language }))
            return
                tmpl:process($template, $model, map {
                    "plainText": false(), 
                    "resolver": vapi:resolver#1,
                    "modules": map {
                        "http://www.tei-c.org/tei-simple/config": map {
                            "prefix": "config",
                            "at": "modules/config.xqm"
                        }
                    }
                })
        else
            router:response(200, "application/json", $works)
    )
};

declare
    %private
function capi:list-works($root as xs:string?, $cached, $params as map(*)) {
    (: session:clear(), :)
    let $sort := head(($params?sort, $config:sort-default))
    let $filter := $params?field
    let $query := $params?query
    let $filtered :=
        if (exists($cached)) then
            $cached
        else
            query:query-metadata($root, ($filter, "div")[1], $query, $sort)
    return (
        session:set-attribute($config:session-prefix || ".timestamp", current-dateTime()),
        session:set-attribute($config:session-prefix || '.hits', $filtered?all),
        session:set-attribute($config:session-prefix || '.params', $params),
        session:set-attribute($config:session-prefix || ".works", $filtered),
        session:set-attribute($config:session-prefix || ".search", $query),
        session:set-attribute($config:session-prefix || ".field", $filter),
        if (empty($cached)) then
            session:set-attribute($config:session-prefix || ".collection", $root)
        else
            (),
        map:merge((
            $filtered,
            map {
                "query": $query,
                "field": $filter,
                "root": 
                    if (exists($cached)) then 
                        session:get-attribute($config:session-prefix || ".collection")
                    else
                        $root
            }
        ))
    )
};

declare function capi:documents($request as map(*)) {
    let $path := if ($request?parameters?path) then xmldb:decode($request?parameters?path) else ()
    let $params := capi:params2map($path)
    let $worksAll := capi:list-works($path, (), $params)
    return
        array {
            for $doc in $worksAll?all
            let $config := tpu:parse-pi(root($doc), $config:default-view, $config:default-odd)
            let $teiHeader := nav:get-header($config, root($doc)/*)
            let $relPath := config:get-identifier($doc)
            let $header :=
                $pm-config:web-transform($teiHeader, map {
                    "display": "browse",
                    "doc": $relPath,
                    "context-path": $request?parameters?link,
                    "static": true()
                }, $config?odd)
            return
                map {
                    "path": $relPath,
                    "content": $header,
                    "view": $config?view,
                    "lastModified": xmldb:last-modified(util:collection-name($doc), util:document-name($doc))
                }
        }
};

declare %private function capi:params2map($root as xs:string?) {
    map:merge((
        for $param in request:get-parameter-names()[not(. = ("start", "per-page", "page", "path"))]
        return
            map:entry($param, request:get-parameter($param, ())),
        map:entry("collection", $root)
    ))
};

declare %private function capi:use-cache($params as map(*), $cached) {
    let $cachedParams := session:get-attribute($config:session-prefix || ".params")
    let $timestamp := session:get-attribute($config:session-prefix || ".timestamp")
    return
        if (exists($cached) and exists($cachedParams) and deep-equal($params, $cachedParams) and exists($timestamp)) then
            empty(xmldb:find-last-modified-since(collection($config:data-default), $timestamp))
        else
            false()
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
                let $collectionPath := $config:data-default || "/" || $root
                return
                    if (xmldb:collection-available($collectionPath)) then
                        if (ends-with($path, ".docx")) then
                            let $mediaPath := $config:data-default || "/" || $root || "/" || xmldb:encode($path) || ".media"
                            let $stored := xmldb:store($collectionPath, xmldb:encode($path), $data)
                            let $tei :=
                                docx:process($stored, $config:data-default, $pm-config:tei-transform(?, ?, "docx.odd"), $mediaPath)
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
                "path": substring-after($path, $config:data-default || "/" || $root),
                "type": xmldb:get-mime-type($path),
                "size": 93928
            }
    })
};