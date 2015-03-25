xquery version "3.1";

(:~
 : Utility functions for parsing an ODD and running a transformation.
 : This module is the main entry point for transformations based on
 : the TEI Simple ODD extensions.
 : 
 : @author Wolfgang Meier
 :)
module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace pm="http://www.tei-c.org/tei-simple/xquery/model" at "model.xql";
import module namespace pmfhtml="http://www.tei-c.org/tei-simple/xquery/functions" at "html-functions.xql";

declare variable $pmu:ERR_UNKNOWN_MODE := xs:QName("pmu:err-mode-unknown");

declare variable $pmu:MODULES := map {
    "web": map {
        "output": "web",
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions",
                "prefix": "html",
                "at": "html-functions.xql"
            }
        ]
    },
    "print": map {
        "output": "print",
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions/latex",
                "prefix": "latex",
                "at": "latex-functions.xql"
            }
        ]
    },
    "fo": map {
        "output": "print",
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions/fo",
                "prefix": "fo",
                "at": "fo-functions.xql"
            }
        ]
    }
};

declare function pmu:process($oddPath as xs:string, $xml as node()*, $output-root as xs:string) {
    pmu:process($oddPath, $xml, $output-root, "web", "")
};

declare function pmu:process($oddPath as xs:string, $xml as node()*, $output-root as xs:string, 
    $mode as xs:string, $relPath as xs:string) {
    let $name := replace($oddPath, "^.*?([^/]+)\.[^/]+$", "$1")
    let $odd := doc($oddPath)
    let $main :=
        if (pmu:requires-update($odd, $output-root, $name || "-" || $mode || "-main.xql")) then
            let $config := pmu:process-odd($odd, $output-root, $mode, $relPath)
            return
                $config?main
        else
            $output-root || "/" || $name || "-" || $mode || "-main.xql"
    let $source := util:binary-to-string(util:binary-doc($main))
    return
        util:eval($source, false(), (xs:QName("xml"), $xml))
};


declare function pmu:process-odd($odd as document-node(), $output-root as xs:string, 
    $mode as xs:string, $relPath as xs:string) as map(*) {
    let $name := replace(util:document-name($odd), "^([^\.]+)\.[^\.]+$", "$1")
    let $module := $pmu:MODULES?($mode)
    return
        if (empty($module)) then
            error($pmu:ERR_UNKNOWN_MODE, "output mode " || $mode || " is unknown")
        else
            let $generated := pm:parse($odd/*, pmu:fix-module-paths($module?modules), $module?output)
            let $xquery := xmldb:store($output-root, $name || "-" || $mode || ".xql", $generated?code, "application/xquery")
            let $style := pmu:extract-styles($odd, $name, $output-root)
            let $mainCode :=
                "import module namespace m='" || $generated?uri || 
                "' at '" || $xquery || "';&#10;&#10;" ||
                "declare variable $xml external;&#10;&#10;" ||
                "let $options := map {&#10;" ||
                '   "styles": ["' || $relPath || "/" || $style || '"]&#10;' ||
                '}&#10;' ||
                "return m:transform($options, $xml)"
            let $main := xmldb:store($output-root, $name || "-" || $mode || "-main.xql", $mainCode, "application/xquery")
            return
                map {
                    "id": $name,
                    "uri": $generated?uri,
                    "module": $xquery,
                    "style": $style,
                    "main": $main
                }
};

declare function pmu:extract-styles($odd as document-node(), $name as xs:string, $output-root as xs:string) {
    let $style := pmfhtml:generate-css($odd)
    let $path :=
        xmldb:store($output-root, $name || ".css", $style, "text/css")
    return
        $name || ".css"
};

declare %private function pmu:requires-update($odd as document-node(), $collection as xs:string, $file as xs:string) {
    let $oddModified := xmldb:last-modified(util:collection-name($odd), util:document-name($odd))
    let $fileModified := xmldb:last-modified($collection, $file)
    return
        empty($fileModified) or $oddModified > $fileModified
};

declare %private function pmu:fix-module-paths($modules as array(*)) {
    array {
        for $module in $modules?*
        return
            map:new(($module, map:entry("at", system:get-module-load-path() || "/" || $module?at)))
    }
};