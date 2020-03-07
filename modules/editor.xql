xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace pb="http://teipublisher.com/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:models($spec as element()) {
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
                "sourcerend": $model/@useSourceRendition = 'true',
                "renditions": local:renditions($model),
                "parameters": local:parameters($model),
                "models": local:models($model),
                "template": local:template($model)
            }
    }
};

declare function local:parameters($model as element()) {
    array {
        for $param in $model/param
        return
            map {
                "name": $param/@name/string(),
                "value": $param/@value/string()
            }
    }
};

declare function local:template($model as element()) {
    string-join($model/pb:template/node() ! serialize(., map { "indent": false() }))
};


declare function local:renditions($model as element()) {
    array {
        for $rendition in $model/outputRendition
        return
            map {
                "scope": $rendition/@scope/string(),
                "css": replace($rendition/string(), "^\s+(.*?)\s+$", "$1")
            }
    }
};

declare function local:load($oddPath as xs:string, $root as xs:string) {
    let $odd := doc($root || "/" || $oddPath)/TEI
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
                            "models": local:models($spec)
                        }
                },
            "namespace": $schemaSpec/@ns/string(),
            "source": $schemaSpec/@source/string(),
            "title": string-join($odd//teiHeader/fileDesc/titleStmt/title[not(@type)]/text()),
            "titleShort": $odd//teiHeader/fileDesc/titleStmt/title[@type = 'short']/string(),
            "description": $odd//teiHeader/fileDesc/titleStmt/title[not(@type)]/desc/text(),
            "cssFile": $odd//teiHeader/encodingDesc/tagsDecl/rendition/@source/string()
        }
};

declare function local:find-spec($oddPath as xs:string, $root as xs:string, $ident as xs:string) {
    let $odd := doc($root || "/" || $oddPath)
    let $spec := $odd//elementSpec[@ident = $ident][model|modelGrp|modelSequence]
    return
        if ($spec) then
            map {
                "status": "found",
                "odd": $oddPath,
                "models": local:models($spec)
            }
        else
            let $source := $odd//schemaSpec/@source
            return
                if ($source) then
                    local:find-spec($source, $root, $ident)
                else
                    map {
                        "status": "not-found"
                    }
};


declare function local:get-line($src, $line as xs:int?) {
    if ($line) then
        let $lines := tokenize($src, "\n")
        return
            subsequence($lines, $line - 1, 3) !
                replace(., "^\s*(.*?)", "$1&#10;")
    else
        ()
};

declare function local:recompile($source as xs:string, $root as xs:string) {
    let $outputRoot := request:get-parameter("output-root", $config:output-root)
    let $outputPrefix := request:get-parameter("output-prefix", $config:output)
    let $oddRoot := request:get-parameter("root", $config:odd-root)
    let $config := doc($oddRoot || "/configuration.xml")/*
    let $odd := doc($oddRoot || "/" || $source)
    let $pi := tpu:parse-pi($odd, ())
    for $module in
        if ($pi?output) then
            tokenize($pi?output)
        else
            ("web", "print", "latex", "epub")
    return
        try {
            for $file in pmu:process-odd(
                odd:get-compiled($root, $source),
                $outputRoot,
                $module,
                "../" || $outputPrefix,
                $config)?("module")
            let $src := util:binary-to-string(util:binary-doc($file))
            let $compiled := util:compile-query($src, ())
            return
                if ($compiled/*:error) then
                    map {
                        "file": $file,
                        "error": $compiled/*:error/string(),
                        "line": $compiled/*:error/@line,
                        "message": local:get-line($src, $compiled/*:error/@line)
                    }
                else
                    map {
                        "file": $file
                    }
        } catch * {
            map {
                "error": "Error for output mode " || $module,
                "message": $err:description
            }
        }
};

declare function local:save($oddPath as xs:string, $root as xs:string, $data as xs:string) {
    let $odd := local:add-tags-decl(doc($root || "/" || $oddPath))
    let $parsed := parse-xml($data)
    let $updated := local:update($odd, $parsed, $odd)
    let $serialized := serialize($updated,
        <output:serialization-parameters>
            <output:indent>true</output:indent>
            <output:omit-xml-declaration>false</output:omit-xml-declaration>
        </output:serialization-parameters>)
    let $stored := xmldb:store($root, $oddPath, $serialized)
    let $report :=
        array {
            local:recompile($oddPath, $root)
        }
    return
        map {
            "odd": $oddPath,
            "report": $report
        }
};

declare function local:update($nodes as node()*, $data as document-node(), $orig as document-node()) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    local:update($node/node(), $data, $orig)
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
                        local:update($node/node(), $data, $orig)
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
                    local:update($node/node(), $data, $orig),
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
                    local:update($node/node(), $data, $orig)
                }
            default return
                $node
};

declare function local:add-tags-decl($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                document {
                    local:add-tags-decl($node/node())
                }
            case element(TEI) return
                element { node-name($node) } {
                    $node/@*,
                    local:add-tags-decl($node/teiHeader),
                    $node/* except $node/teiHeader
                }
            case element(teiHeader) return
                element { node-name($node) } {
                    $node/@*,
                    $node/fileDesc,
                    if ($node/encodingDesc) then
                        local:add-tags-decl($node/encodingDesc)
                    else
                        <encodingDesc xmlns="http://www.tei-c.org/ns/1.0">
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
                        <tagsDecl xmlns="http://www.tei-c.org/ns/1.0">
                        </tagsDecl>,
                    $node/* except $node/tagsDecl
                }
            default return
                $node
};

declare function local:lint() {
    let $code := request:get-parameter("code", ())
    let $query := ``[xquery version "3.1";declare variable $parameters := map {};declare variable $node := ();() ! (
`{$code}`
)
    ]``
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


let $action := request:get-parameter("action", "load")
let $oddPath := request:get-parameter("odd", ())
let $root := request:get-parameter("root", $config:odd-root)
let $data := request:get-parameter("data", ())
let $ident := request:get-parameter("ident", ())
return
    switch ($action)
        case "save" return
            local:save($oddPath, $root, $data)
        case "find" return
            local:find-spec($oddPath, $root, $ident)
        case "lint" return
            local:lint()
        default return
            local:load($oddPath, $root)
