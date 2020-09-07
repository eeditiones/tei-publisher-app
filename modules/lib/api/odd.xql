xquery version "3.1";

module namespace oapi="http://teipublisher.com/api/odd";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace pb="http://teipublisher.com/1.0";

import module namespace router="http://exist-db.org/xquery/router" at "/db/apps/oas-router/content/router.xql";
import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare variable $oapi:EXIDE :=
    let $path := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    return
        if ($path) then
            substring-after(util:collection-name($path), repo:get-root())
        else
            ();

declare function oapi:load-source($href as xs:string, $line as xs:int?) {
    let $link :=
        let $path := string-join(
            (request:get-context-path(), request:get-attribute("$exist:prefix"), $oapi:EXIDE,
            "index.html?open=" || $href)
            , "/"
        )
        return
            replace($path, "/+", "/")
    return
        <a href="{$link}" target="eXide" class="eXide-open" data-exide-open="{$href}"
            data-exide-line="{$line}">{$href}</a>
};

declare function oapi:get-line($src, $line as xs:int?) {
    if ($line) then
        let $lines := tokenize($src, "\n")
        return
            subsequence($lines, $line - 1, 3) !
                replace(., "^\s*(.*?)", "$1&#10;")
    else
        ()
};

declare function oapi:recompile($request as map(*)) {
    let $odd := $request?parameters?odd
    let $odd :=
        if (exists($odd)) then
            $odd
        else
            ($config:odd-available, $config:odd-internal)
    let $result :=
        for $source in $odd
        let $odd := doc($config:odd-root || "/" || $source)
        let $pi := tpu:parse-pi($odd, (), $source)
        for $module in
            if ($pi?output) then
                tokenize($pi?output)
            else
                ("web", "print", "latex", "epub")
        return
            try {
                for $output in pmu:process-odd(
                    odd:get-compiled($config:odd-root, $source),
                    $config:output-root,
                    $module,
                    "../" || $config:output,
                    $config:module-config)
                let $file := $output?module
                return
                    if ($output?error) then
                        <div class="list-group-item-danger">
                            <h5 class="list-group-item-heading">{$file}: ERROR</h5>
                            <p class="list-group-item-text">{ $output?error/error/string() }</p>
                            <pre class="list-group-item-text">{ oapi:get-line($output?code, $output?error/error/@line) }</pre>
                            <p class="list-group-item-text">File not saved.</p>
                        </div>
                    else if ($request?parameters?check) then
                        let $src := util:binary-to-string(util:binary-doc($file))
                        let $compiled := util:compile-query($src, ())
                        return
                            if ($compiled/error) then
                                <div class="list-group-item-danger">
                                    <h5 class="list-group-item-heading">{oapi:load-source($file, $compiled/error/@line)}:</h5>
                                    <p class="list-group-item-text">{ $compiled/error/string() }</p>
                                    <pre class="list-group-item-text">{ oapi:get-line($src, $compiled/error/@line)}</pre>
                                </div>
                            else
                                <div class="list-group-item-success">
                                    <h5 class="list-group-item-heading">{$file}: OK</h5>
                                </div>
                    else
                        <div class="list-group-item-success">
                            <h5 class="list-group-item-heading">{$file}: OK</h5>
                        </div>
            } catch * {
                <div class="list-group-item-danger">
                    <h5 class="list-group-item-heading">Error for output mode {$module}</h5>
                    <p class="list-group-item-text">{ $err:description }</p>
                </div>
            }
    return
        <div class="errors">
            <h4>Regenerated XQuery code from ODD files</h4>
            <div class="list-group">
            {
                $result
            }
            </div>
        </div>
};

declare function oapi:list-odds($request as map(*)) {
    array {
        dbutil:scan-resources(xs:anyURI($config:odd-root), function ($resource) {
            if (ends-with($resource, ".odd")) then
                let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
                let $displayName := (
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "short"]/string(),
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text(),
                    $name
                )[1]
                let $description :=  doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/tei:desc/string()
                return
                    map {
                        "name": $name,
                        "label": $displayName,
                        "description": $description,
                        "path": $resource,
                        "canWrite": sm:has-access(xs:anyURI($resource), "rw-")
                    }
            else
                ()
        })
    }
};

declare function oapi:delete-odd($request as map(*)) {
    let $path := $config:odd-root || "/" || $request?parameters?odd
    return
        if (doc-available($path)) then
            let $deleted := xmldb:remove($config:odd-root, $request?parameters?odd)
            return
                router:response(410, ())
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};

declare %private function oapi:parse-template($nodes as node()*, $odd as xs:string, $title as xs:string?) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node()
                return
                    oapi:parse-template($node/node(), $odd, $title)
            case element(tei:schemaSpec)
                return
                    element {node-name($node)} {
                        $node/@*,
                        attribute ident {$odd},
                        oapi:parse-template($node/node(), $odd, $title)
                    }
            case element(tei:title)
                return
                    element {node-name($node)} {
                        $node/@*,
                        $title
                    }
            case element(tei:change)
                return
                    element {node-name($node)} {
                        attribute when {current-date()},
                        "Initial version"
                    }
            case element()
                return
                    element {node-name($node)} {
                        $node/@*,
                        oapi:parse-template($node/node(), $odd, $title)
                    }
            default
                return
                    $node
};

declare function oapi:create-odd($request as map(*)) {
    let $template := doc($config:odd-root || "/template.odd.xml")
    let $parsed := document {oapi:parse-template($template, $request?parameters?odd, $request?parameters?title)}
    let $stored := xmldb:store($config:odd-root, $request?parameters?odd || ".odd", $parsed, "text/xml")
    return (
        oapi:compile($request?parameters?odd),
        router:response(201, "application/json", map {
            "path": $stored
        })
    )
};

declare %private function oapi:compile($odd) {
    for $module in ("web", "print", "latex", "epub")
    let $result :=
        pmu:process-odd(
            odd:get-compiled($config:odd-root, $odd || ".odd"),
            $config:output-root,
            $module,
            "../" || $config:output,
            $config:module-config
        )
    return
        ()
};

declare %private function oapi:models($spec as element()) {
    array {
        for $model in $spec/(tei:model|tei:modelGrp|tei:modelSequence)
        return
            map {
                "type": local-name($model),
                "desc": $model/tei:desc/string(),
                "output": $model/@output/string(),
                "behaviour": $model/@behaviour/string(),
                "predicate": $model/@predicate/string(),
                "css": $model/@cssClass/string(),
                "sourcerend": $model/@useSourceRendition = 'true',
                "renditions": oapi:renditions($model),
                "parameters": oapi:parameters($model),
                "models": oapi:models($model),
                "template": oapi:template($model)
            }
    }
};

declare %private function oapi:parameters($model as element()) {
    array {
        for $param in $model/tei:param
        return
            map {
                "name": $param/@name/string(),
                "value": $param/@value/string()
            }
    }
};

declare %private function oapi:template($model as element()) {
    string-join($model/pb:template/node() ! serialize(., map { "indent": false() }))
};


declare %private function oapi:renditions($model as element()) {
    array {
        for $rendition in $model/tei:outputRendition
        return
            map {
                "scope": $rendition/@scope/string(),
                "css": replace($rendition/string(), "^\s+(.*?)\s+$", "$1")
            }
    }
};

declare %private function oapi:to-json($odd as document-node(), $path as xs:string) {
    let $schemaSpec := $odd//tei:schemaSpec
    return
        map {
            "elementSpecs":
                array {
                    for $spec in $odd//tei:elementSpec[tei:model|tei:modelGrp|tei:modelSequence]
                    order by $spec/@ident
                    return
                        map {
                            "ident": $spec/@ident/string(),
                            "mode": $spec/@mode/string(),
                            "models": oapi:models($spec)
                        }
                },
            "namespace": $schemaSpec/@ns/string(),
            "source": $schemaSpec/@source/string(),
            "title": string-join($odd//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)]/text()),
            "titleShort": $odd//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'short']/string(),
            "description": $odd//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)]/tei:desc/text(),
            "cssFile": $odd//tei:teiHeader/tei:encodingDesc/tei:tagsDecl/tei:rendition/@source/string(),
            "canWrite": sm:has-access(xs:anyURI($path), "rw-")
        }
};

declare function oapi:find-spec($oddPath as xs:string, $root as xs:string, $ident as xs:string) {
    let $odd := doc($root || "/" || $oddPath)
    let $spec := $odd//tei:elementSpec[@ident = $ident][tei:model|tei:modelGrp|tei:modelSequence]
    return
        if ($spec) then
            map {
                "status": "found",
                "odd": $oddPath,
                "models": oapi:models($spec)
            }
        else
            let $source := $odd//tei:schemaSpec/@source
            return
                if ($source) then
                    oapi:find-spec($source, $root, $ident)
                else
                    map {
                        "status": "not-found"
                    }
};

declare function oapi:get-odd($request as map(*)) {
    let $root := head(($request?parameters?root, $config:odd-root))
    return
        if (exists($request?parameters?ident)) then
            router:response(
                200,
                "application/json",
                oapi:find-spec($request?parameters?odd, $root, $request?parameters?ident)
            )
        else
            let $path := $root || "/" || $request?parameters?odd
            return
                if (doc-available($path)) then
                    let $odd := doc($path)
                    return
                        if ("application/json" = router:accepted-content-types()) then
                            router:response(200, "application/json", oapi:to-json($odd, $path))
                        else
                            $odd
                else
                    error($errors:NOT_FOUND, "ODD not found: " || $path)
};