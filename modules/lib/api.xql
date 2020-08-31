xquery version "3.1";

declare namespace api="https://tei-publisher.com/xquery/api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router" at "/db/apps/oas-router/content/router.xql";
import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace nav-tei="http://www.tei-c.org/tei-simple/navigation/tei" at "../navigation-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace mapping="http://www.tei-c.org/tei-simple/components/map" at "../map.xql";
import module namespace dbutil = "http://exist-db.org/xquery/dbutil";
import module namespace oapi="http://teipublisher.com/api/odd" at "api/odd.xql";
import module namespace dapi="http://teipublisher.com/api/documents" at "api/document.xql";
import module namespace capi="http://teipublisher.com/api/collection" at "api/collection.xql";
import module namespace sapi="http://teipublisher.com/api/search" at "api/search.xql";

declare %private function api:get-fragment($request as map(*)) {
    let $doc := xmldb:decode-uri($request?parameters?doc)
    let $view := head(($request?parameters?view, $config:default-view))
    let $xml :=
        if ($request?parameters?xpath) then
            for $document in config:get-document($doc)
            let $namespace := namespace-uri-from-QName(node-name($document/*))
            let $xquery := "declare default element namespace '" || $namespace || "'; $document" || $request?parameters?xpath
            let $data := util:eval($xquery)
            return
                if ($data) then
                    pages:load-xml($data, $view, $request?parameters?root, $doc)
                else
                    ()

        else if (exists($request?parameters?id)) then (
            for $document in config:get-document($doc)
            let $config := tpu:parse-pi($document, $view)
            let $data :=
                if (count($request?parameters?id) = 1) then
                    nav:get-section-for-node($config, $document/id($request?parameters?id))
                else
                    let $ms1 := $document/id($request?parameters?id[1])
                    let $ms2 := $document/id($request?parameters?id[2])
                    return
                        if ($ms1 and $ms2) then
                            nav-tei:milestone-chunk($ms1, $ms2, $document/tei:TEI)
                        else
                            ()
            return
                map {
                    "config": map:merge(($config, map { "context": $document })),
                    "odd": $config?odd,
                    "view": $config?view,
                    "data": $data
                }
        ) else
            pages:load-xml($view, $request?parameters?root, $doc)
    return
        if ($xml?data) then
            let $userParams :=
                map:merge((
                    request:get-parameter-names()[starts-with(., 'user')] ! map { substring-after(., 'user.'): request:get-parameter(., ()) },
                    map { "webcomponents": 6 }
                ))
            let $mapped :=
                if ($request?parameters?map) then
                    let $mapFun := function-lookup(xs:QName("mapping:" || $request?parameters?map), 2)
                    let $mapped := $mapFun($xml?data, $userParams)
                    return
                        $mapped
                else
                    $xml?data
            let $data :=
                if (empty($request?parameters?xpath) and $request?parameters?highlight and exists(session:get-attribute($config:session-prefix || ".query"))) then
                    query:expand($xml?config, $mapped)[1]
                else
                    $mapped
            let $content :=
                if (not($view = "single")) then
                    pages:get-content($xml?config, $data)
                else
                    $data

            let $html :=
                typeswitch ($mapped)
                    case element() | document-node() return
                        pages:process-content($content, $xml?data, $xml?config, $userParams)
                    default return
                        $content
            let $transformed := api:extract-footnotes($html[1])
            let $doc := replace($doc, "^.*/([^/]+)$", "$1")
            return
                if ($request?parameters?format = "html") then
                    router:response(200, "text/html", $transformed?content)
                else
                    router:response(200, "application/json",
                        map {
                            "format": $request?parameters?format,
                            "view": $view,
                            "doc": $doc,
                            "root": $request?parameters?root,
                            "odd": $xml?config?odd,
                            "next":
                                if ($view != "single") then
                                    let $next := $config:next-page($xml?config, $xml?data, $view)
                                    return
                                        if ($next) then
                                            util:node-id($next)
                                        else ()
                                else
                                    (),
                            "previous":
                                if ($view != "single") then
                                    let $prev := $config:previous-page($xml?config, $xml?data, $view)
                                    return
                                        if ($prev) then
                                            util:node-id($prev)
                                        else
                                            ()
                                else
                                    (),
                            "switchView":
                                if ($view != "single") then
                                    let $node := pages:switch-view-id($xml?data, $view)
                                    return
                                        if ($node) then
                                            util:node-id($node)
                                        else
                                            ()
                                else
                                    (),
                            "content": serialize($transformed?content,
                                <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                                <output:indent>no</output:indent>
                                <output:method>html5</output:method>
                                    </output:serialization-parameters>),
                            "footnotes": $transformed?footnotes,
                            "userParams": $userParams
                        }
                    )
        else
            map { "error": "Not found" }
};

declare function api:extract-footnotes($html as element()*) {
    map {
        "footnotes": $html/div[@class="footnotes"],
        "content":
            element { node-name($html) } {
                $html/@*,
                $html/node() except $html/div[@class="footnotes"]
            }
    }
};

declare function api:list-templates($request as map(*)) {
    array {
        for $html in collection($config:app-root || "/templates/pages")/*
        let $description := $html//meta[@name="description"]/@content/string()
        return
            map {
                "name": util:document-name($html),
                "title": $description
            }
    }
};

let $lookup := function($name as xs:string) {
    function-lookup(xs:QName($name), 1)
}
let $resp := router:route("modules/lib/api.json", $lookup)
return
    $resp