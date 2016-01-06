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
 : Utility functions for generating CSS from an ODD or parsing CSS into a map.
 : 
 : @author Wolfgang Meier
 :)
module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function css:parse-css($css as xs:string) {
    map:new(
        let $analyzed := analyze-string($css, "\.?(.*?)\s*\{\s*([^\}]*?)\s*\}", "m")
        for $match in $analyzed/fn:match
        let $selector := $match/fn:group[@nr = "1"]/string()
        let $styles := map:new(
            for $match in analyze-string($match/fn:group[@nr = "2"], "\s*(.*?)\s*\:\s*['&quot;]?(.*?)['&quot;]?\;")/fn:match
            return
                map:entry($match/fn:group[1]/string(), $match/fn:group[2]/string())
        )
        return
            map:entry($selector, $styles)
    )
};

declare function css:generate-css($root as document-node()) {
    string-join((
        "/* Generated stylesheet. Do not edit. */&#10;",
        "/* Generated from " || document-uri($root) || " */&#10;&#10;",
        "/* Global styles */&#10;",
        for $rend in $root//tei:outputRendition[@xml:id][not(parent::tei:model)]
        return
            "&#10;.simple_" || $rend/@xml:id || " { " || 
            normalize-space($rend/string()) || " }",
        "&#10;&#10;/* Model rendition styles */&#10;",
        for $model in $root//tei:model[tei:outputRendition]
        let $spec := $model/ancestor::tei:elementSpec[1]
        let $count := count($spec//tei:model)
        for $rend in $model/tei:outputRendition
        let $className :=
            if ($count > 1) then
                $spec/@ident || count($model/preceding::tei:model[. >> $spec]) + 1
            else
                $spec/@ident/string()
        let $class :=
            if ($rend/@scope) then
                $className || ":" || $rend/@scope
            else
                $className
        return
            "&#10;.tei-" || $class || " { " ||
            normalize-space($rend) || " }"
    ))
};

declare function css:get-rendition($node as node()*, $class as xs:string) {
    if ($node/@rendition) then
        for $rend in tokenize($node/@rendition, "\s+")
        return
            if (starts-with($rend, "#")) then
                'document_' || substring-after($rend,'#')
            else if (starts-with($rend,'simple:')) then
                translate($rend,':','_')
            else
                $rend
    else
        $class
};