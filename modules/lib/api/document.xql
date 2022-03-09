xquery version "3.1";

module namespace dapi="http://teipublisher.com/api/documents";

import module namespace router="http://exist-db.org/xquery/router";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../pages.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace nav-tei="http://www.tei-c.org/tei-simple/navigation/tei" at "../../navigation-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../../query.xql";
import module namespace mapping="http://www.tei-c.org/tei-simple/components/map" at "../../map.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace xslfo="http://exist-db.org/xquery/xslfo" at "java:org.exist.xquery.modules.xslfo.XSLFOModule";
import module namespace epub="http://exist-db.org/xquery/epub" at "../epub.xql";
import module namespace docx="http://existsolutions.com/teipublisher/docx";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $dapi:CACHE := true();

declare variable $dapi:CACHE_COLLECTION := $config:app-root || "/cache";

declare function dapi:metadata($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    let $xml := config:get-document($doc)
    return
        if (exists($xml)) then
            let $config := tpu:parse-pi(root($xml), ())
            return map {
                "title": nav:get-document-title($config, root($xml)/*) => normalize-space(),
                "view": $config?view,
                "odd": $config?odd,
                "template": $config?template,
                "collection": substring-after(util:collection-name($xml), $config:data-root || "/")
            }
        else
            error($errors:NOT_FOUND, "Document " || $doc || " not found")
};

declare function dapi:delete($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($id)
    return
        if ($doc) then
            let $del := xmldb:remove(util:collection-name($doc), util:document-name($doc))
            return
                router:response(410, '')
        else
            error($errors:NOT_FOUND, "Document " || $id || " not found")
};

declare function dapi:source($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    return
        if ($doc) then
            let $path := xmldb:encode-uri($config:data-root || "/" || $doc)
            let $filename := replace($doc, "^.*/([^/]+)$", "$1")
            let $mime := ($request?parameters?type, xmldb:get-mime-type($path))[1]
            return
                if (util:binary-doc-available($path)) then
                    response:stream-binary(util:binary-doc($path), $mime, $filename)
                else if (doc-available($path)) then
                    router:response(200, $mime, doc($path))
                else
                    error($errors:NOT_FOUND, "Document " || $doc || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
};

declare function dapi:html($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    return
        if ($doc) then
            let $xml := config:get-document($doc)
            return
                if (exists($xml)) then
                    let $config := tpu:parse-pi(root($xml), ())
                    let $out := $pm-config:web-transform($xml, map { "root": $xml, "webcomponents": 7 }, $config?odd)
                    let $styles := if (count($out) > 1) then $out[1] else ()
                    return
                        dapi:postprocess(($out[2], $out[1])[1], $styles, $config?odd, $request?parameters?base, $request?parameters?wc)
                else
                    error($errors:NOT_FOUND, "Document " || $doc || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
};

declare function dapi:postprocess($nodes as node()*, $styles as element()?, $odd as xs:string?, 
    $base as xs:string?, $components as xs:boolean?) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(head) return
                let $oddName := replace($odd, "^.*/([^/\.]+)\.?.*$", "$1")
                return
                    element { node-name($node) } {
                        $node/@*,
                        if ($base) then
                            <base href="{$base}"/>
                        else
                            (),
                        <meta charset="utf-8"/>,
                        $node/node(),
                        <link rel="stylesheet" type="text/css" href="transform/{replace($oddName, "^(.*)\.odd$", "$1")}.css"/>,
                        <link rel="stylesheet" type="text/css" href="transform/{replace($oddName, "^(.*)\.odd$", "$1")}-print.css" media="print"/>,
                        $styles,
                        if ($components) then (
                            <style rel="stylesheet" type="text/css">
                            a[rel=footnote] {{
                                font-size: var(--pb-footnote-font-size, var(--pb-content-font-size, 75%));
                                font-family: var(--pb-footnote-font-family, --pb-content-font-family);
                                vertical-align: super;
                                text-decoration: none;
                                padding: var(--pb-footnote-padding, 0 0 0 .25em);
                            }}
                            .footnote .fn-number {{
                                float: left;
                                font-size: var(--pb-footnote-font-size, var(--pb-content-font-size, 75%));
                            }}
                            </style>,
                            <script defer="defer" src="https://unpkg.com/@webcomponents/webcomponentsjs@2.4.3/webcomponents-loader.js"></script>,
                            switch ($config:webcomponents)
                                case "dev" return
                                    <script type="module" src="{$config:webcomponents-cdn}/src/pb-components-bundle.js"></script>
                                case "local" return
                                    <script type="module" src="resources/scripts/pb-components-bundle.js"></script>
                                default return
                                    <script type="module" src="{$config:webcomponents-cdn}@{$config:webcomponents}/dist/pb-components-bundle.js"></script>
                        ) else
                            ()

                    }
            case element(body) return
                let $content := (
                    dapi:postprocess($node/node(), $styles, $odd, $base, $components),
                    let $footnotes := 
                        for $fn in root($node)//*[@class = "footnote"]
                        return
                            element { node-name($fn) } {
                                $fn/@*,
                                dapi:postprocess($fn/node(), $styles, $odd, $base, $components)
                            }
                    return
                        nav:output-footnotes($footnotes)
                )
                return
                    element { node-name($node) } {
                        $node/@*,
                        if ($components and not($node//pb-page)) then
                            <pb-page endpoint="{$base}">{$content}</pb-page>
                        else
                            $content
                    }
            case element() return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        dapi:postprocess($node/node(), $styles, $odd, $base, $components)
                    }
            default return
                $node
};

declare function dapi:latex($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $token := $request?parameters?token
    let $source := $request?parameters?source
    return (
        if ($token) then
            response:set-cookie("simple.token", $token)
        else
            (),
        if ($id) then
            let $xml := config:get-document($id)/*
            return
                if (exists($xml)) then
                    let $config := tpu:parse-pi(root($xml), ())
                    let $options :=
                        map {
                            "root": $xml,
                            "image-dir": config:get-repo-dir() || "/" ||
                                substring-after($config:data-root[1], $config:app-root) || "/"
                        }
                    let $tex := string-join($pm-config:latex-transform($xml, $options, $config?odd))
                    let $file :=
                        replace($id, "^.*?([^/]+)$", "$1") || format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]")
                    return
                        if ($source) then
                            router:response(200, "application/x-latex", $tex)
                        else
                            let $serialized := file:serialize-binary(util:string-to-binary($tex), $config:tex-temp-dir || "/" || $file || ".tex")
                            let $options :=
                                <option>
                                    <workingDir>{$config:tex-temp-dir}</workingDir>
                                </option>
                            let $outputPath := $config:tex-temp-dir || "/" || $file || ".pdf"
                            let $cleanup := if (file:exists($outputPath)) then file:delete($outputPath) else ()
                            let $output0 :=
                                process:execute(
                                    ( $config:tex-command($file) ), $options
                                )
                            return
                                if (not(file:exists($outputPath))) then
                                    error($errors:BAD_REQUEST, "LaTeX reported errors", dapi:latex-error($output0))
                                else
                                    let $output :=
                                        for $i in 1 to 2
                                        return
                                            process:execute(
                                                ( $config:tex-command($file) ), $options
                                            )
                                    return
                                        let $pdf := file:read-binary($config:tex-temp-dir || "/" || $file || ".pdf")
                                        return
                                            response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                else
                    error($errors:NOT_FOUND, "Document " || $id || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
    )
};

declare function dapi:latex-error($output as element()) {
    "exit code: " || $output/@exitCode/string() || "&#10;&#10;" ||
    string-join(
        for $line in $output//line
        return
            $line || "&#10;"
    )

};

declare function dapi:cache($id as xs:string, $output as xs:base64Binary) {
    dapi:prepare-cache-collection(),
    xmldb:store($dapi:CACHE_COLLECTION, $id || ".pdf", $output, "application/pdf")
};

declare function dapi:get-cached($id as xs:string, $doc as node()) {
    let $path := $dapi:CACHE_COLLECTION || "/" ||  $id || ".pdf"
    return
        if ($dapi:CACHE and util:binary-doc-available($path)) then
            let $modDatePDF := xmldb:last-modified($dapi:CACHE_COLLECTION, $id || ".pdf")
            let $modDateSrc := xmldb:last-modified(util:collection-name($doc), util:document-name($doc))
            return
                if ($modDatePDF >= $modDateSrc) then
                    util:binary-doc($path)
                else
                    ()
        else
            ()
};

declare function dapi:prepare-cache-collection() {
    if (xmldb:collection-available($dapi:CACHE_COLLECTION)) then
        ()
    else
        (xmldb:create-collection($config:app-root, "cache"))[2]
};

declare function dapi:pdf($request as map(*)) {
    let $token := head(($request?parameters?token, "none"))[1]
    let $useCache := $request?parameters?cache
    let $id := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($id)
    let $config := tpu:parse-pi(root($doc), ())
    let $name := util:document-name($doc)
    return
        if ($doc) then
            let $cached := if ($useCache) then dapi:get-cached($name, $doc) else ()
            return (
                response:set-cookie("simple.token", $token),
                if (not($request?parameters?source) and exists($cached)) then (
                    response:stream-binary($cached, "media-type=application/pdf", $id || ".pdf")
                ) else
                    let $start := util:system-time()
                    let $fo := $pm-config:print-transform($doc, map { "root": $doc }, $config?odd)
                    return (
                        if ($request?parameters?source) then
                            router:response(200, "application/xml", $fo)
                        else
                            let $output := xslfo:render($fo, "application/pdf", (), $config:fop-config)
                            return
                                typeswitch($output)
                                    case xs:base64Binary return 
                                        if ($useCache) then
                                            let $path := dapi:cache($name, $output)
                                            return
                                                response:stream-binary(util:binary-doc($path), "media-type=application/pdf", $id || ".pdf")
                                        else
                                            response:stream-binary($output, "media-type=application/pdf", $id || ".pdf")
                                    default return
                                        $output
                    )
            )
        else
            ()
};

declare function dapi:epub($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $work := config:get-document($id)
    return
        if (exists($work)) then
            let $entries := dapi:work2epub($request, $id, $work, $request?parameters?lang)
            return
                (
                    if ($request?parameters?token) then
                        response:set-cookie("simple.token", $request?parameters?token)
                    else
                        (),
                    response:set-header("Content-Disposition", concat("attachment; filename=", concat($id, '.epub'))),
                    response:stream-binary(
                        compression:zip( $entries, true() ),
                        'application/epub+zip',
                        concat($id, '.epub')
                    )
                )
        else
            error($errors:NOT_FOUND, "Document " || $id || " not found")
};

declare %private function dapi:work2epub($request as map(*), $id as xs:string, $work as document-node(), $lang as xs:string?) {
    let $config := $config:epub-config($work, $lang)
    let $odd := head(($request?parameters?odd, $config:default-odd))
    let $oddName := replace($odd, "^([^/\.]+).*$", "$1")
    let $cssDefault := util:binary-to-string(util:binary-doc($config:output-root || "/" || $oddName || ".css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
    return
        epub:generate-epub($config, $work/*, $css, $id)
};

declare function dapi:get-fragment($request as map(*)) {
    let $doc := xmldb:decode-uri($request?parameters?doc)
    let $view := head(($request?parameters?view, $config:default-view))
    let $xml :=
        if ($request?parameters?xpath) then
            for $document in config:get-document($doc)
            let $namespace := namespace-uri-from-QName(node-name(root($document)/*))
            let $xquery := "declare default element namespace '" || $namespace || "'; $document" || $request?parameters?xpath
            let $data := util:eval($xquery)
            return
                if ($data) then
                    pages:load-xml($data, $view, $request?parameters?root, $doc)
                else
                    ()

        else if (exists($request?parameters?id)) then (
            for $document in config:get-document($doc)
            let $config := tpu:parse-pi(root($document), $view)
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
                    map { "webcomponents": 7 }
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
            let $transformed := dapi:extract-footnotes($html[1])
            let $doc := replace($doc, "^.*/([^/]+)$", "$1")
            return
                if ($request?parameters?format = "html") then
                    router:response(200, "text/html", $transformed?content)
                else
                    let $next := if ($view = "single") then () else $config:next-page($xml?config, $xml?data, $view)
                    let $prev := if ($view = "single") then () else $config:previous-page($xml?config, $xml?data, $view)
                    return
                        router:response(200, "application/json",
                            map {
                                "format": $request?parameters?format,
                                "view": $view,
                                "doc": $doc,
                                "root": $request?parameters?root,
                                "rootNode": util:node-id($xml?data[1]),
                                "id": $content/@xml:id/string(),
                                "odd": $xml?config?odd,
                                "next":
                                    if ($next) then
                                        util:node-id($next)
                                    else (),
                                "previous":
                                    if ($prev) then
                                        util:node-id($prev)
                                    else
                                        (),
                                "nextId": 
                                    if ($next) then
                                        $next/@xml:id/string()
                                    else (),
                                "previousId":
                                    if ($prev) then
                                        $prev/@xml:id/string()
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
                                "footnotes": serialize($transformed?footnotes,
                                    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                                        <output:indent>no</output:indent>
                                        <output:method>html5</output:method>
                                    </output:serialization-parameters>
                                ),
                                "userParams": $userParams,
                                "collection": dapi:get-collection($xml?data[1])
                            }
                        )
        else
            error($errors:NOT_FOUND, "Document " || $doc || " not found")
};

declare function dapi:get-collection($data) {
    let $collection := util:collection-name($data)
    return
        if ($collection) then
            substring-after($collection, $config:data-root || "/")
        else
            ()
};

declare %private function dapi:extract-footnotes($html as element()*) {
        map {
        "footnotes": $html/div[@class="footnotes"],
        "content":
            element { node-name($html) } {
                $html/@*,
                $html/node() except $html/div[@class="footnotes"]
            }
    }
};

declare function dapi:table-of-contents($request as map(*)) {
    let $doc := xmldb:decode-uri($request?parameters?id)
    let $view := head(($request?parameters?view, $config:default-view))
    let $xml := pages:load-xml($view, (), $doc)
    return
        if (exists($xml)) then
            pages:toc-div(root($xml?data), $xml, $request?parameters?target, $request?parameters?icons)
        else
            error($errors:NOT_FOUND, "Document " || $doc || " not found")
};

declare function dapi:preview($request as map(*)) {
    let $config := tpu:parse-pi($request?body, (), $request?parameters?odd)
    let $html := $pm-config:web-transform($request?body, map { "root": $request?body, "webcomponents": 7 }, $config?odd)
    return
        dapi:postprocess($html, (), $config?odd, $request?parameters?base, $request?parameters?wc)
};

declare function dapi:convert-docx($request as map(*)) {
    let $transform := $pm-config:tei-transform(?, ?, $request?parameters?odd)
    return
        docx:process-pkg($request?body, $transform)
};