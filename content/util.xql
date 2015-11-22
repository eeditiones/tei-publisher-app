(: 
 : Copyright 2015, Wolfgang Meier
 : 
 : This software is dual-licensed: 
 : 
 : 1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
 : http://creativecommons.org/licenses/by-sa/3.0/ 
 : 
 : 2. http://www.opensource.org/licenses/BSD-2-Clause 
 : 
 : All rights reserved. Redistribution and use in source and binary forms, with or without 
 : modification, are permitted provided that the following conditions are met: 
 : 
 : * Redistributions of source code must retain the above copyright notice, this list of 
 : conditions and the following disclaimer. 
 : * Redistributions in binary form must reproduce the above copyright
 : notice, this list of conditions and the following disclaimer in the documentation
 : and/or other materials provided with the distribution. 
 : 
 : This software is provided by the copyright holders and contributors "as is" and any 
 : express or implied warranties, including, but not limited to, the implied warranties 
 : of merchantability and fitness for a particular purpose are disclaimed. In no event 
 : shall the copyright holder or contributors be liable for any direct, indirect, 
 : incidental, special, exemplary, or consequential damages (including, but not limited to, 
 : procurement of substitute goods or services; loss of use, data, or profits; or business
 : interruption) however caused and on any theory of liability, whether in contract,
 : strict liability, or tort (including negligence or otherwise) arising in any way out
 : of the use of this software, even if advised of the possibility of such damage.
 :)
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
import module namespace css="http://www.tei-c.org/tei-simple/xquery/css" at "css.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $pmu:ERR_UNKNOWN_MODE := xs:QName("pmu:err-mode-unknown");

declare variable $pmu:MODULES := map {
    "web": map {
        "output": ["web"],
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions",
                "prefix": "html",
                "at": "html-functions.xql"
            }
        ]
    },
    "print": map {
        "output": ["fo", "print"],
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions/fo",
                "prefix": "fo",
                "at": "fo-functions.xql"
            }
        ]
    },
    "epub": map {
        "output": ["epub", "web"],
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions",
                "prefix": "html",
                "at": "html-functions.xql"
            },
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions/epub",
                "prefix": "epub",
                "at": "ext-epub.xql"
            }
        ]
    },
    "latex": map {
        "output": ["latex", "print"],
        "modules": [
            map {
                "uri": "http://www.tei-c.org/tei-simple/xquery/functions/latex",
                "prefix": "latex",
                "at": "latex-functions.xql"
            }
        ]
    }
};

declare function pmu:process($oddPath as xs:string, $xml as node()*, $output-root as xs:string) {
    pmu:process($oddPath, $xml, $output-root, "web", "", ())
};

declare function pmu:process($oddPath as xs:string, $xml as node()*, $output-root as xs:string, 
    $mode as xs:string, $relPath as xs:string, $config as element(modules)?) {
    pmu:process($oddPath, $xml, $output-root, $mode, $relPath, $config, ())
};

declare function pmu:process($oddPath as xs:string, $xml as node()*, $output-root as xs:string, 
    $mode as xs:string, $relPath as xs:string, $config as element(modules)?, $parameters as map(*)?) {
    let $name := replace($oddPath, "^.*?([^/]+)\.[^/]+$", "$1")
    let $odd := doc($oddPath)
    let $main :=
        if (pmu:requires-update($odd, $output-root, $name || "-" || $mode || "-main.xql")) then
            let $config := pmu:process-odd($odd, $output-root, $mode, $relPath, $config)
            return
                $config?main
        else
            $output-root || "/" || $name || "-" || $mode || "-main.xql"
    let $source := util:binary-to-string(util:binary-doc($main))
    return
        util:eval($source, false(), (xs:QName("xml"), $xml, xs:QName("parameters"), $parameters))
};


declare function pmu:process-odd($odd as document-node(), $output-root as xs:string, 
    $mode as xs:string, $relPath as xs:string, $config as element(modules)?) as map(*) {
    let $name := replace(util:document-name($odd), "^([^\.]+)\.[^\.]+$", "$1")
    let $modulesDefault := $pmu:MODULES?($mode)
    let $ext-modules := pmu:parse-config($name, $mode, $config)
    let $module :=
        if (exists($ext-modules)) then
            map:new(($modulesDefault, map:entry("modules", array { $modulesDefault?modules?*, $ext-modules })))
        else
            $modulesDefault
    return
        if (empty($module)) then
            error($pmu:ERR_UNKNOWN_MODE, "output mode " || $mode || " is unknown")
        else
            let $log := console:log("output mode is " || $module?output)
            let $generated := pm:parse($odd/*, pmu:fix-module-paths($module?modules), $module?output?*)
            let $xquery := xmldb:store($output-root, $name || "-" || $mode || ".xql", $generated?code, "application/xquery")
            let $style := pmu:extract-styles($odd, $name, $output-root)
            let $main := pmu:generate-main($name, $generated?uri, $xquery, $ext-modules, $output-root, $mode, $relPath, $style)
            let $module := pmu:generate-module($name, $generated?uri, $xquery, $ext-modules, $output-root, $mode, $relPath, $style)
            return
                map {
                    "id": $name,
                    "uri": $generated?uri,
                    "module": $xquery,
                    "style": $style,
                    "main": $main
                }
};

declare function pmu:generate-module($name as xs:string, $uri as xs:string, $xqueryFile as xs:string, $ext-modules as map(*)*, $output-root as xs:string,
    $mode as xs:string, $relPath as xs:string?, $style as xs:string?) {
    let $mainCode :=
        "module namespace pml='" || $uri || "/module';&#10;&#10;" ||
        "import module namespace m='" || $uri || 
        "' at '" || $xqueryFile || "';&#10;&#10;" ||
        "(: Generated library module to be directly imported into code which&#10;" ||
        " : needs to transform TEI nodes using the ODD this module is based on.&#10;" ||
        " :)&#10;" ||
        "declare function pml:transform($xml as node()*, $parameters as map(*)?) {&#10;&#10;" ||
        "   let $options := map {&#10;" ||
        pmu:properties($ext-modules) ||
        '       "styles": ["' || $relPath || "/" || $style || '"],&#10;' ||
        '       "collection": "' || $output-root || '",&#10;' ||
        '       "parameters": $parameters&#10;' ||
        '   }&#10;' ||
        "   return m:transform($options, $xml)&#10;" ||
        "};"
    return
        xmldb:store($output-root, $name || "-" || $mode || "-module.xql", $mainCode, "application/xquery")
};

declare function pmu:generate-main($name as xs:string, $uri as xs:string, $xqueryFile as xs:string, $ext-modules as map(*)*, $output-root as xs:string,
    $mode as xs:string, $relPath as xs:string?, $style as xs:string?) {
    let $mainCode :=
        "import module namespace m='" || $uri || 
        "' at '" || $xqueryFile || "';&#10;&#10;" ||
        "declare variable $xml external;&#10;&#10;" ||
        "declare variable $parameters external;&#10;&#10;" ||
        "let $options := map {&#10;" ||
        pmu:properties($ext-modules) ||
        '    "styles": ["' || $relPath || "/" || $style || '"],&#10;' ||
        '    "collection": "' || $output-root || '",&#10;' ||
        '    "parameters": $parameters&#10;' ||
        '}&#10;' ||
        "return m:transform($options, $xml)"
    return
        xmldb:store($output-root, $name || "-" || $mode || "-main.xql", $mainCode, "application/xquery")
};

declare function pmu:extract-styles($odd as document-node(), $name as xs:string, $output-root as xs:string) {
    let $style := css:generate-css($odd)
    let $path :=
        xmldb:store($output-root, $name || ".css", $style, "text/css")
    return
        $name || ".css"
};

declare %private function pmu:parse-config($odd as xs:string, $mode as xs:string, $config as element(modules)?) {
    if ($config) then
        for $module in $config/output[@mode = $mode][not(@odd) or @odd = $odd]/module
        return
            map {
                "uri": $module/@uri,
                "prefix": $module/@prefix,
                "at": $module/@at,
                "properties": $module/property
            }
    else
        ()
};

declare function pmu:properties($modules as map(*)*) {
    let $properties :=
        for $module in $modules
        for $property in $module?properties
        return
            '    "' || $property/@name || '": ' || normalize-space($property)
    return
        if (exists($properties)) then
            string-join($properties, ",&#10;") || ",&#10;"
        else
            ()
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
            if (matches($module?at, "^(/|xmldb:).*")) then
                $module
            else
                map:new(($module, map:entry("at", system:get-module-load-path() || "/" || $module?at)))
    }
};