xquery version "3.1";

module namespace page="http://teipublisher.com/ns/templates/page";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace mapping="http://www.tei-c.org/tei-simple/components/map" at "../map.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../lib/pages.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../lib/util.xql";

declare namespace expath="http://expath.org/ns/pkg";

declare variable $page:EXIDE :=
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");

declare function page:system() {
    map {
        "publisher": $config:expath-descriptor/@version/string(),
        "api": json-doc($config:app-root || "/modules/lib/api.json")?info?version
    }
};

declare function page:parameter($context as map(*), $name as xs:string) {
    page:parameter($context, $name, ())
};

(:~
 : Get a parameter from the request. Return the default value if the parameter
 : is not present.
 :)
declare function page:parameter($context as map(*), $name as xs:string, $default as item()*) {
    let $reqParam := head(($context?request?parameters?($name), request:get-parameter($name, ())))
    return
        if (exists($reqParam)) then
            $reqParam
        else
            $default
};

(:~ Primary language subtag, lowercase (e.g. en-US → en). :)
declare %private function page:primary-lang($tag as xs:string?) as xs:string? {
    if (not(normalize-space($tag))) then
        ()
    else
        let $range := tokenize(normalize-space($tag), ';')[1]
        let $before-hyphen := head(tokenize($range, '-'))
        return
            lower-case(head(tokenize($before-hyphen, '_')))
};

(:~ First Accept-Language preference that matches a supported code (order preserved). :)
declare %private function page:lang-from-accept-language($header as xs:string?, $supported as xs:string*) as xs:string? {
    if (empty($supported) or not(normalize-space($header))) then
        ()
    else
        head(
            filter(
                tokenize($header, ',') ! page:primary-lang(tokenize(., ';')[1]),
                function ($primary) { $primary and $primary = $supported }
            )
        )
};

(:~
 : Effective UI language: non-empty lang query param (primary subtag), else the
 : language stored in the "lang" cookie (set by language.js when the user picks a
 : language) if it is supported, else Accept-Language if it matches defaults/languages,
 : else defaults.language or first default.
 :)
declare function page:resolve-language($context as map(*)) as xs:string? {
    let $param := page:parameter($context, 'lang')
    let $supported := $context?defaults?languages?*
    let $fromCookie := page:primary-lang(request:get-cookie-value('lang'))[. = $supported]
    let $fromHeader := page:lang-from-accept-language(request:get-header('Accept-Language'), $supported)
    return
        if (string-length(normalize-space($param)) gt 0) then
            page:primary-lang($param)
        else
            head(($fromCookie, $fromHeader, $context?defaults?language, $context?defaults?languages?1))
};

(:~
 : Generate a breadcrumb trail for the current collection.
 :)
declare function page:collection-breadcrumbs($context as map(*)) {
    if (exists($context?doc)) then
        let $components := config:get-relpath($context?doc?content, $config:data-default) => tokenize("/")
        return
            if (count($components) = 1) then
                <li>
                    <a href="{$context?context-path}/{$context?defaults?browse}?collection=">
                        <pb-i18n key="breadcrumb.document-root">
                            Home
                        </pb-i18n>
                    </a>
                </li>
            else
                for $i in 1 to count($components) - 1
                return
                    <li>
                        <a href="{$context?context-path}/{$context?defaults?browse}?collection={string-join(subsequence($components, 1, $i), '/')}">
                            <pb-i18n key="breadcrumb.{string-join(subsequence($components, 1, $i), '.')}">
                                {$components[$i]}
                            </pb-i18n>
                        </a>
                    </li>
    else ()
};

(:~
 : Render the content fragment requested by the current page URL to HTML, so it
 : can be injected into <pb-view> as light-DOM content. A crawler that does not
 : execute JavaScript (or before the components upgrade) then sees the real text
 : instead of an empty component; <pb-view> ignores this light DOM (it has no
 : <slot>) and still fetches and renders into its shadow DOM for interactive use,
 : so the user experience is unchanged.
 :
 : When view-static is enabled (context or defaults) and defaults.data-static
 : is set, the fragment is preferably loaded from the pre-generated cache under
 : that subdirectory (same index/key lookup as pb-view's static mode). On a
 : miss, the fragment is selected from the request parameters the same way as
 : the api/parts/{doc}/json endpoint (dapi:get-fragment): the persistent "id"
 : (xml:id) wins over the volatile "root" (node id); with neither, the first
 : fragment is rendered. This makes every per-fragment URL the sitemap emits
 : (e.g. ?id=intro-jinks) resolve server-side to that fragment's text.
 :
 : @param $context the templating context (expects $context?doc with content/path/view)
 : @return the transformed HTML nodes for the requested fragment, or empty if no document
 :)
declare function page:content($context as map(*)) {
    page:content($context, ())
};

(:~
 : As page:content#1 but first narrows the document to the nodes selected by
 : $xpath, matching a pb-view that carries an xpath attribute (e.g. a
 : source/translation column). Pass the same expression as the pb-view.
 :)
declare function page:content($context as map(*), $xpath as xs:string?) {
    page:content($context, $xpath, ())
};

(:~
 : As page:content#2, but passes additional parameters to the ODD, mirroring the
 : <pb-param> elements of the pb-view (sent as user.* parameters by the parts API).
 : Use this whenever the pb-view carries pb-param children which change the output,
 : otherwise the server-side rendered fragment will differ from what pb-view would load.
 :)
declare function page:content($context as map(*), $xpath as xs:string?, $params as map(*)?) {
    if (exists($context?doc?content)) then
        let $fromCache := page:content-from-static($context, $xpath)
        return
            if (exists($fromCache)) then
                $fromCache
            else
                page:content-dynamic($context, $xpath, $params)
    else
        ()
};

(:~
 : Load a pre-generated part from the data-static cache directory, mirroring
 : pb-view._staticUrl: read `${data-static}/${doc.path}/index.json`, look up a
 : key built from odd/view[/xpath][/map][/id|/root], then load the referenced
 : part JSON. Returns empty if view-static is disabled, data-static is unset,
 : the index is missing, or no key matches — caller then falls back to dynamic
 : rendering.
 :)
declare %private function page:content-from-static($context as map(*), $xpath as xs:string?) {
    let $enabled := ($context?view-static, $context?defaults?view-static) = true()
    let $dataStatic := if ($enabled) then normalize-space($context?defaults?data-static) else ()
    return
        if (not($dataStatic) or not($context?doc?path)) then
            ()
        else
            let $base := string-join(($config:app-root, $dataStatic, $context?doc?path), "/")
            let $indexPath := $base || "/index.json"
            return
                if (not(util:binary-doc-available($indexPath))) then
                    ()
                else
                    let $index := parse-json(util:binary-to-string(util:binary-doc($indexPath)))
                    let $file := page:static-part-file($index, $context, $xpath)
                    let $partPath := if ($file) then $base || "/" || $file else ()
                    return
                        if (not($partPath) or not(util:binary-doc-available($partPath))) then
                            ()
                        else
                            try {
                                let $json := parse-json(util:binary-to-string(util:binary-doc($partPath)))
                                return
                                    page:wrap-ssr($json?rootNode, $json?content, $json?footnotes)
                            } catch * {
                                ()
                            }
};

(:~
 : Resolve the part filename from an index map using the same key order as
 : pb-view._staticUrl: prefer a key that includes id (when set) or root (when
 : set), then fall back to the base key without position (first chunk).
 :)
declare %private function page:static-part-file($index as map(*), $context as map(*), $xpath as xs:string?) as xs:string? {
    let $baseParams := page:static-base-params($context, $xpath)
    let $id := normalize-space(page:parameter($context, 'id'))
    let $root := normalize-space(page:parameter($context, 'root'))
    let $keys := (
        if ($id) then
            page:static-key(map:merge(($baseParams, map { "id": $id })))
        else if ($root) then
            page:static-key(map:merge(($baseParams, map { "root": $root })))
        else
            (),
        page:static-key($baseParams)
    )
    return
        head(
            for $key in $keys
            let $file := $index($key)
            where exists($file) and not($file instance of map(*) or $file instance of array(*))
            let $name := string($file)
            where string-length($name) gt 0
            return
                $name
        )
};

(:~
 : Parameters that participate in the static index key (odd, view, optional
 : xpath/map), matching the paramNames list in pb-view._staticUrl plus values
 : from getParameters.
 :)
declare %private function page:static-base-params($context as map(*), $xpath as xs:string?) as map(*) {
    let $odd :=
        let $o := head(($context?doc?odd, $config:default-odd))
        return
            if (ends-with($o, '.odd')) then $o else $o || '.odd'
    let $view := head(($context?doc?view, $config:default-view))
    let $map := normalize-space(page:parameter($context, 'map'))
    return
        map:merge((
            map {
                "odd": $odd,
                "view": $view
            },
            if (normalize-space($xpath)) then map { "xpath": $xpath } else (),
            if ($map) then map { "map": $map } else ()
        ))
};

(:~ Sorted query-string key, same algorithm as pb-view createKey / static:compute-key. :)
declare %private function page:static-key($params as map(*)) as xs:string {
    string-join(
        for $key in map:keys($params)
        order by $key
        return
            $key || "=" || $params($key),
        "&amp;"
    )
};

(:~
 : Build the light-DOM SSR wrappers from serialized part content/footnotes
 : (as stored in static part JSON). Empty content yields empty sequence.
 :)
declare %private function page:wrap-ssr($nodeId as item()?, $content as item()?, $footnotes as item()?) {
    let $contentStr := if (exists($content)) then string($content) else ()
    return
        if (not(normalize-space($contentStr))) then
            ()
        else
            try {
                let $contentNodes := parse-xml-fragment($contentStr)
                let $footnoteStr := if (exists($footnotes)) then string($footnotes) else ()
                let $footnoteNodes :=
                    if (normalize-space($footnoteStr)) then
                        parse-xml-fragment($footnoteStr)
                    else
                        ()
                let $id := if (exists($nodeId)) then string($nodeId) else ""
                return
                    (
                        element div {
                            attribute data-pb-ssr { $id },
                            $contentNodes
                        },
                        if (exists($footnoteNodes)) then
                            element div {
                                attribute data-pb-ssr-footnotes { $id },
                                $footnoteNodes
                            }
                        else
                            ()
                    )
            } catch * {
                ()
            }
};

(:~ Dynamic ODD transform path used when the static cache has no matching part. :)
declare %private function page:content-dynamic($context as map(*), $xpath as xs:string?, $params as map(*)?) {
    let $view := head(($context?doc?view, $config:default-view))
    let $xml := page:fragment($context, $context?doc?content, $view, $context?doc?path, $xpath)
    return
        if (exists($xml?data)) then
            let $content :=
                if ($view = "single") then
                    $xml?data
                else
                    pages:get-content($xml?config, $xml?data)
            let $nodeId := util:node-id($xml?data[1])
            let $rendered := page:unwrap-body(
                pages:process-content($content, $xml?data, $xml?config, map:merge((map { "webcomponents": 7 }, $params)), ())
            )
            (: process-content collects footnotes into a sibling <div class="footnotes">
             : (wrapping everything in a content div). Split it out so the markup
             : matches the parts API response (resp.content / resp.footnotes) and
             : pb-view can adopt content and footnotes the same way for SSR and
             : dynamic loads. :)
            let $footnotes := $rendered/div[@class = "footnotes"]
            return
                (
                    (: Content block; pb-view detects this marker, adopts it into
                     : its shadow DOM and requests content=none so the fragment is
                     : not rendered a second time. :)
                    element div {
                        attribute data-pb-ssr { $nodeId },
                        if (exists($footnotes)) then
                            element { node-name($rendered) } {
                                $rendered/@*,
                                $rendered/node() except $footnotes
                            }
                        else
                            $rendered
                    },
                    if (exists($footnotes)) then
                        element div {
                            attribute data-pb-ssr-footnotes { $nodeId },
                            $footnotes
                        }
                    else
                        ()
                )
        else
            ()
};

(:~ Narrow $data to the nodes selected by $xpath, evaluated with the document's
 : default element namespace. Mirrors dapi:apply-xpath in the document API. :)
declare %private function page:apply-xpath($data as node()*, $xpath as xs:string?) {
    if ($xpath) then
        let $namespace := namespace-uri-from-QName(node-name(root($data[1])/*))
        return
            util:eval("declare default element namespace '" || $namespace || "'; $data" || $xpath)
    else
        $data
};

(:~
 : Resolve the fragment requested by the current page URL to a { config, data }
 : map, mirroring the selection of the parts API (dapi:get-fragment) so a page
 : URL and its corresponding parts/{doc}/json request return the same fragment.
 :
 : $xpath, when given, scopes the lookup to a sub-document (e.g. a
 : source/translation column) before the fragment is resolved within it. The
 : persistent "id" (xml:id) parameter wins over the volatile "root" (node id);
 : it is resolved to an actual node (for "div" view expanded to its section via
 : nav:get-section-for-node), never round-tripped through util:node-id. With no
 : resolvable id, pages:load-xml handles the "root" node id or the first fragment.
 :
 : @param $context templating context, used only to read the id/root parameters
 : @param $document the full document content
 : @param $view the view (div/page/single/...)
 : @param $path the document path, passed through to pages:load-xml
 : @param $xpath optional expression scoping the lookup, or empty for the whole document
 : @return a map with "config" and "data" entries, or empty if nothing resolves
 :)
declare function page:fragment($context as map(*), $document as node()*, $view as xs:string?,
    $path as xs:string?, $xpath as xs:string?) as map(*)? {
    let $view := head(($view, $config:default-view))
    let $id := page:parameter($context, 'id')
    let $root := page:parameter($context, 'root')
    let $ctx := page:apply-xpath($document, $xpath)
    let $node :=
        if (string-length(normalize-space($id)) gt 0 and $view != "single") then
            $ctx/id($id)
        else
            ()
    return
        if (exists($node)) then
            let $config := tpu:parse-pi(root($document), $view)
            return
                map {
                    "config": map:merge(($config, map { "context": $ctx }), map { "duplicates": "use-last" }),
                    "data":
                        if ($view = "div") then
                            nav:get-section-for-node($config, $node)
                        else
                            $node
                }
        else if (exists($ctx)) then
            pages:load-xml($ctx, $view, $root, $path)
        else
            ()
};

(:~ The transform wraps its output in an HTML <body> element. Inlining that into
 : the page would nest a second <body>, which the HTML parser rejects (it closes
 : the real document body early and reparents the content out of <main>). Rewrite
 : any such <body> wrapper to a <div>, keeping attributes and children. Other
 : elements are passed through untouched to preserve their namespaces. :)
declare %private function page:unwrap-body($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(body) return
                element div { $node/@*, $node/node() }
            case element() return
                if ($node/body) then
                    element { node-name($node) } { $node/@*, page:unwrap-body($node/node()) }
                else
                    $node
            default return
                $node
};

declare function page:transform($nodes as node()*) {
    page:transform($nodes, (), ())
};

declare function page:transform($nodes as node()*, $parameters as map(*)?) {
    page:transform($nodes, $parameters, ())
};

declare function page:transform($nodes as node()*, $parameters as map(*)?, $odd as xs:string?) {
    page:transform($nodes, $parameters, $odd, ())
};

(:~
 : Transform a sequence of nodes to HTML using the given odd and parameters.
 :
 : @param $nodes the nodes to transform
 : @param $parameters the parameters to use for the transformation
 : @param $odd the odd to use for the transformation
 : @param $mapFunction name of mapping function to apply to the nodes before transformation
 : @return the transformed nodes
 :)
declare function page:transform($nodes as node()*, $parameters as map(*)?, $odd as xs:string?, $mapFunction as xs:string?) {
    let $mappingFun := 
        if ($mapFunction) then
            function-lookup(xs:QName("mapping:" || $mapFunction), 2)
        else
            ()
    let $odd := head(($odd, $config:default-odd))
    for $node in $nodes
    let $mapped :=
        if (exists($mappingFun)) then
            $mappingFun($node, $parameters)
        else
            $node
    let $params := map:merge((
        $parameters,
        map { 
            "webcomponents": 7, 
            "context-path": $config:context-path, 
            "root": head(($parameters?root, $node))
        }
    ))
    return
        pages:process-content(
            $mapped,
            head(($parameters?root, $node)),
            map { "odd": $odd },
            $params,
            ()
        )
};