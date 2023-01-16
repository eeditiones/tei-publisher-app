xquery version "3.1";

module namespace oapi="http://teipublisher.com/api/odd";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace pb="http://teipublisher.com/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace router="http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

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
    let $oddRoot := head(($request?parameters?root, $config:odd-root))
    let $outputRoot := head(($request?parameters?output-root, $config:output-root))
    let $outputPrefix := head(($request?parameters?output-prefix, $config:output))
    let $oddConfig := doc($oddRoot || "/configuration.xml")/*
    let $odd :=
        if (exists($odd)) then
            $odd
        else
            ($config:odd-available, $config:odd-internal)
    let $result :=
        for $source in $odd
        let $odd := doc($oddRoot || "/" || $source)
        let $pi := tpu:parse-pi($odd, (), $source)
        for $module in
            if ($pi?output) then
                tokenize($pi?output)
            else
                ("web", "print", "latex", "epub", "fo")
        return
            try {
                for $output in pmu:process-odd(
                    odd:get-compiled($oddRoot, $source),
                    $outputRoot,
                    $module,
                    $outputPrefix,
                    $oddConfig,
                    $module = "web")
                let $file := $output?module
                return
                    if ($output?error) then
                        <div class="list-group-item-danger">
                            <h5 class="list-group-item-heading">{$file}: ERROR</h5>
                            <p class="list-group-item-text">{ $output?error/error/string() }</p>
                            <h5 class="list-group-item-heading">Compilation error on line {$output?error/error/@line/string()}:</h5>
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
        for $doc in xmldb:get-child-resources(xs:anyURI($config:odd-root))
        let $resource := $config:odd-root || "/" || $doc
        where ends-with($resource, ".odd")
        let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
        let $displayName := (
            doc($resource)/TEI/teiHeader/fileDesc/titleStmt/title[@type = "short"]/string(),
            doc($resource)/TEI/teiHeader/fileDesc/titleStmt/title/text(),
            $name
        )[1]
        let $description :=  doc($resource)/TEI/teiHeader/fileDesc/titleStmt/title/desc/string()
        return
            map {
                "name": $name,
                "label": $displayName,
                "description": $description,
                "path": $resource,
                "canWrite": sm:has-access(xs:anyURI($resource), "rw-")
            }
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
            case element(schemaSpec)
                return
                    element {node-name($node)} {
                        $node/@*,
                        attribute ident {$odd},
                        oapi:parse-template($node/node(), $odd, $title)
                    }
            case element(title)
                return
                    element {node-name($node)} {
                        $node/@*,
                        $title
                    }
            case element(change)
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

declare function oapi:save-odd($request as map(*)) {
    let $root := head(($request?parameters?root, $config:odd-root))
    let $oddPath := analyze-string($request?parameters?odd, '\.odd')//fn:non-match/string()

    let $canWrite := sm:has-access(xs:anyURI($root || "/" || $request?parameters?odd), "rw-")
return
    if ($canWrite) then
(: let $orig := doc($root || "/" || $request?parameters?odd) :)
        let $odd := oapi:add-tags-decl(doc($root || "/" || $request?parameters?odd))
        let $oddPath := analyze-string($request?parameters?odd, '\.odd')//fn:non-match/string()

        let $updated := oapi:update($odd, $request?body, $odd) => oapi:normalize-ns()
    
        let $stored := xmldb:store($root, $request?parameters?odd, $updated, "text/xml")

        let $report := oapi:recompile($request)

        return 
            router:response(201, "application/json", map {
                "path": $stored,
                "report": $report
            })
    else 
            router:response(401, "application/json", map {
                "status": "denied",
                "path": $request?parameters?odd,
                "report": "[You don't have write access to " || $root || "/" || $request?parameters?odd || "]"
            })

};

declare %private function oapi:compile($odd) {
    for $module in ("web", "print", "latex", "epub", "fo")
    let $result :=
        pmu:process-odd(
            odd:get-compiled($config:odd-root, $odd || ".odd"),
            $config:output-root,
            $module,
            $config:output,
            $config:module-config,
            $module = "web"
        )
    return
        ()
};

declare %private function oapi:models($spec as element()) {
    array {
        for $model in $spec/(model|modelGrp|modelSequence)
        return
            map {
                "type": local-name($model),
                "desc": $model/desc/string(),
                "output": $model/@output/string(),
                "behaviour": $model/@behaviour/string(),
                "predicate": $model/@predicate/string(),
                "css": $model/@cssClass/string(),
                "mode": if ($model/@pb:mode) then $model/@pb:mode/string() else '',
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
        for $param in $model/param
        return
            map {
                "name": $param/@name/string(),
                "value": $param/@value/string()
            },
        for $param in $model/pb:set-param
        return
            map {
                "name": $param/@name/string(),
                "value": $param/@value/string(),
                "set": true()
            }
    }
};

declare %private function oapi:template($model as element()) {
    string-join($model/pb:template/node() ! serialize(., map { "indent": false() }))
};


declare %private function oapi:renditions($model as element()) {
    array {
        for $rendition in $model/outputRendition
        return
            map {
                "scope": $rendition/@scope/string(),
                "css": replace($rendition/string(), "^\s+(.*?)\s+$", "$1")
            }
    }
};

declare %private function oapi:to-json($odd as document-node(), $path as xs:string) {
    let $schemaSpec := $odd//schemaSpec
    return
        map {
            "elementSpecs":
                array {
                    for $spec in $odd//elementSpec[model|modelGrp|modelSequence]
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
            "title": string-join($odd//teiHeader/fileDesc/titleStmt/title[not(@type)]/text()),
            "titleShort": $odd//teiHeader/fileDesc/titleStmt/title[@type = 'short']/string(),
            "description": $odd//teiHeader/fileDesc/titleStmt/title[not(@type)]/desc/text(),
            "cssFile": $odd//teiHeader/encodingDesc/tagsDecl/rendition/@source/string(),
            "canWrite": sm:has-access(xs:anyURI($path), "rw-")
        }
};

declare function oapi:find-spec($oddPath as xs:string, $root as xs:string, $ident as xs:string) {
    let $odd := doc($root || "/" || $oddPath)
    let $spec := $odd//elementSpec[@ident = $ident][model|modelGrp|modelSequence]
    return
        if ($spec) then
            map {
                "status": "found",
                "odd": $oddPath,
                "models": oapi:models($spec)
            }
        else
            let $source := $odd//schemaSpec/@source
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

declare function oapi:lint($request as map(*)) {
    let $code := $request?parameters?code
    let $query := ``[xquery version "3.1";declare variable $parameters := map {};declare variable $mode := '';declare variable $node := ();declare variable $get := (); () ! (
`{$code}`
)]``
    let $r := util:compile-query($query, ())
    return
        if ($r/@result = 'fail') then
            let $error := $r/*:error
            let $msg := $error/string()
            let $analyzed := analyze-string($msg, ".*line:?\s(\d+).*?column\s(\d+)")
            let $analyzed :=
                if ($analyzed//fn:group) then
                    $analyzed
                else
                    analyze-string($msg, "line\s(\d+):(\d+)")
            let $parsedLine := $analyzed//fn:group[1]
            let $parsedColumn := $analyzed//fn:group[2]
            let $line :=
                if ($parsedLine) then
                    number($parsedLine)
                else
                    number($error/@line)
            let $column :=
                if ($parsedColumn) then
                    number($parsedColumn)
                else
                    number($error/@column)
            let $lineCount :=
                count(analyze-string($code, "\n")//fn:match)
            return
                map {
                    "status": "fail",
                    "line": if ($line < 2 or $line - 1 > $lineCount) then 1 else $line - 1,
                    "rline": $error,
                    "column": $column,
                    "message": $msg
                }
        else
            map {
                "status": "pass"
            }
};

declare function oapi:update($nodes as node()*, $data as document-node(), $orig as document-node()) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    oapi:update($node/node(), $data, $orig)
                }
            case element(TEI) return
                    element { node-name($node) } {
                        for $prefix in in-scope-prefixes($node)[. != "http://www.tei-c.org/ns/1.0"][. != ""]
                        let $namespace := namespace-uri-for-prefix($prefix, $node)
                        return
                            namespace { $prefix } { $namespace }
                        ,
                        if ("http://teipublisher.com/1.0" = in-scope-prefixes($node)) then
                            ()
                        else
                            namespace pb { "http://teipublisher.com/1.0" },
                        $node/@*,
                        oapi:update($node/node(), $data, $orig)
                    }
            case element(titleStmt) return
                element { node-name($node) } {
                    $node/@*,
                    $data/schemaSpec/title[text()],
                    $node/* except $node/title
                }
            case element(tagsDecl) return
                element { node-name($node) } {
                    $node/@*,
                    $node/* except $node/rendition[@source],
                    $data/schemaSpec/rendition[@source]
                }
            case element(schemaSpec) return
                element { node-name($node) } {
                    $node/@* except ($node/@ns, $node/@source),
                    (: Save namespace attribute if specified :)
                    if ($data/schemaSpec/@ns) then
                        $data/schemaSpec/@ns
                    else
                        (),
                    $data/schemaSpec/@source,
                    oapi:update($node/node(), $data, $orig),
                    for $spec in $data//elementSpec
                    where empty($orig//elementSpec[@ident = $spec/@ident])
                    return
                        $spec
                }
            case element(elementSpec) return
                let $newSpec := $data//elementSpec[@ident=$node/@ident]
                return
                    element { node-name($node) } {
                        $node/@ident,
                        $node/@mode,
                        $node/* except ($node/model, $node/modelGrp, $node/modelSequence),
                        $newSpec/*
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    oapi:update($node/node(), $data, $orig)
                }
            default return
                $node
};

declare %private function oapi:normalize-ns($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document { oapi:normalize-ns($node/node()) }
            case element(TEI) return
                element { node-name($node) } {
                    for $prefix in in-scope-prefixes($node)[. != "http://www.tei-c.org/ns/1.0"][. != ""]
                    let $namespace := namespace-uri-for-prefix($prefix, $node)
                    return
                        namespace { $prefix } { $namespace },
                    $node/@*,
                    oapi:normalize-ns($node/node())
                }
            case element(pb:behaviour) | element(pb:param) | element(pb:set-param) return
                element { node-name($node) } {
                    $node/@*,
                    oapi:normalize-ns($node/node())
                }
            case element(pb:template) return
                <pb:template xmlns="" xml:space="preserve">
                { $node/node() }
                </pb:template>
            case element() return
                element { QName(namespace-uri($node), local-name($node)) } {
                    $node/@*,
                    oapi:normalize-ns($node/node())
                }
            default return
                $node
};

declare function oapi:add-tags-decl($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                document {
                    oapi:add-tags-decl($node/node())
                }
            case element(TEI) return
                element { node-name($node) } {
                    for $prefix in in-scope-prefixes($node)[. != "http://www.tei-c.org/ns/1.0"][. != ""]
                    let $namespace := namespace-uri-for-prefix($prefix, $node)
                    return
                        namespace { $prefix } { $namespace },
                    $node/@*,
                    oapi:add-tags-decl($node/teiHeader),
                    $node/* except $node/teiHeader
                }
            case element(teiHeader) return
                element { node-name($node) } {
                    $node/@*,
                    $node/fileDesc,
                    if ($node/encodingDesc) then
                        oapi:add-tags-decl($node/encodingDesc)
                    else
                        <encodingDesc>
                            <tagsDecl></tagsDecl>
                        </encodingDesc>,
                    $node/* except ($node/fileDesc, $node/encodingDesc)
                }
            case element(encodingDesc) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/tagsDecl) then
                        $node/tagsDecl
                    else
                        <tagsDecl>
                        </tagsDecl>,
                    $node/* except $node/tagsDecl
                }
            default return
                $node
};