xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "/db/apps/tei-publisher/modules/config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:models($spec as element()) {
    array {
        for $model in $spec/(model|modelGrp|modelSequence)
        return
            map {
                "type": local-name($model),
                "output": $model/@output/string(),
                "behaviour": $model/@behaviour/string(),
                "predicate": $model/@predicate/string(),
                "class": $model/@cssClass/string(),
                "renditions": local:renditions($model),
                "parameters": local:parameters($model),
                "models": local:models($model)
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

declare function local:load($oddPath as xs:string) {
    array {
        let $odd := doc($config:odd-root || "/" || $oddPath)/TEI
        for $spec in $odd//elementSpec
        return
            map {
                "ident": $spec/@ident/string(),
                "mode": $spec/@mode/string(),
                "models": local:models($spec)
            }
    }
};

declare function local:find-spec($oddPath as xs:string, $ident as xs:string) {
    let $odd := doc($config:odd-root || "/" || $oddPath)
    let $spec := $odd//elementSpec[@ident = $ident]
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
                    local:find-spec($source, $ident)
                else
                    map {
                        "status": "not-found"
                    }
};


declare function local:get-line($src, $line as xs:int) {
    let $lines := tokenize($src, "\n")
    return
        subsequence($lines, $line - 1, 3) !
            replace(., "^\s*(.*?)", "$1&#10;")
};

declare function local:recompile($source as xs:string) {
    console:log("Recompiling " || $source),
    for $module in ("web", "print", "latex", "epub")
    return
        try {
            for $file in pmu:process-odd(
                odd:get-compiled($config:odd-root, $source),
                $config:output-root,
                $module,
                "../" || $config:output,
                $config:module-config)?("module")
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

declare function local:save($oddPath as xs:string, $data as xs:string) {
    let $odd := doc($config:odd-root || "/" || $oddPath)
    let $parsed := parse-xml($data)
    let $updated := local:update($odd, $parsed)
    let $serialized := serialize($updated, map { "indent": true(), "omit-xml-declaration": false() })
    let $stored := xmldb:store($config:odd-root, $oddPath, $serialized)
    let $report :=
        array {
            local:recompile($oddPath)
        }
    return
        map {
            "odd": $oddPath,
            "report": $report
        }
};

declare function local:update($nodes as node()*, $data as document-node()) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    local:update($node/node(), $data)
                }
            case element(schemaSpec) return
                element { node-name($node) } {
                    $node/@*,
                    $data/schemaSpec/*
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    local:update($node/node(), $data)
                }
            default return
                $node
};

let $action := request:get-parameter("action", "load")
let $oddPath := request:get-parameter("odd", ())
let $data := request:get-parameter("data", ())
let $ident := request:get-parameter("ident", ())
return
    switch ($action)
        case "save" return
            local:save($oddPath, $data)
        case "find" return
            local:find-spec($oddPath, $ident)
        default return
            local:load($oddPath)
