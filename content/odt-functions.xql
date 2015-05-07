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
 : Function module to produce HTML output. The functions defined here are called 
 : from the generated XQuery transformation module. Function names must match
 : those of the corresponding TEI Processing Model functions.
 : 
 : @author Wolfgang Meier
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/odt";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace text="urn:oasis:names:tc:opendocument:xmlns:text:1.0";
declare namespace style="urn:oasis:names:tc:opendocument:xmlns:style:1.0";
declare namespace fo="http://www.w3.org/1999/XSL/Format";

declare variable $pmf:CSS_PROPERTIES := map {
    "font-family": "fo:font-family",
    "font-weight": "fo:font-weight",
    "font-size": "fo:font-size",
    "font-style": "fo:font-style"
};
    
declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string, $content) {
    <text:p text:style-name="{$class}">
    {
        $config?apply-children($config, $node, $content)
    }
    </text:p>
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string, $content, $type, $subdiv) {
    let $level := 
        if ($content instance of element()) then
            max((count($content/ancestor::tei:div), 1))
        else
            4
    return
        <text:h text:outline-level="{$level}" text:style-name="{$class}">
        {
            $config?apply-children($config, $node, $content)
        }
        </text:h>
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string, $content) {
    switch($node/@type)
        case "ordered" return
            <text:list>{$config?apply-children($config, $node, $content)}</text:list>
        default return
            <text:list>{$config?apply-children($config, $node, $content)}</text:list>
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string, $content) {
    <text:list-item>{$config?apply-children($config, $node, $content)}</text:list-item>
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string, $id as item()*) {
    ()
};

declare function pmf:glyph($config as map(*), $node as element(), $class as xs:string, $content as xs:anyURI?) {
    if ($content = "char:EOLhyphen") then
        "&#xAD;"
    else
        ()
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string, $url as xs:anyURI,
    $width, $height, $scale) {
    ()
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string, $content, $place as xs:string?, $n as xs:string?) {
    ()
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string, $content) {
    <text:span text:style-name="{$class}">
    {
        $config?apply-children($config, $node, $content)
    }
    </text:span>
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string, $content) {
    string($content)
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:index($config as map(*), $node as element(), $class as xs:string, $content, $type as xs:string) {
    ()
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string, $type as xs:string, $label as item()*) {
    switch($type)
        case "page" return
            <text:soft-page-break/>
        default return
            ()
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string, $content) {
    ()
};

declare function pmf:alternate($config as map(*), $node as element(), $class as xs:string, $option1 as node()*,
    $option2 as node()*) {
    <text:span>
        <text:span>{$config?apply-children($config, $node, $option1)}</text:span>
        <text:span class="hidden altcontent">{$config?apply-children($config, $node, $option2)}</text:span>
    </text:span>
};

declare function pmf:match($config as map(*), $node as element(), $content) {
    ()
};

declare function pmf:escapeChars($text as item()) {
    $text
};

declare function pmf:get-rendition($node as node()*, $class as xs:string) {
    let $rend := $node/@rendition
    return
        if ($rend) then
            if (starts-with($rend, "#")) then
                'document_' || substring-after(.,'#')
            else if (starts-with($rend,'simple:')) then
                translate($rend,':','_')
            else
                $rend
        else
            $class
};

declare function pmf:styles($config as map(*)) {
    let $config := pmf:load-styles($config, doc($config?odd))
    for $class in $config?styles?*[not(contains(., ":"))]
    return
        <style:style style:name="{$class}" style:family="paragraph">
            <style:text-properties>
            {
                let $styles := pmf:filter-styles($config?styles?($class))
                return
                    if (exists($styles)) then
                        for $style in $styles?*
                        return
                            attribute { $style } { $styles($style) }
                    else
                        ()
            }
            </style:text-properties>
        </style:style>
};

declare function pmf:load-styles($config as map(*), $root as document-node()) {
    let $css := pmf:generate-css($root)
    let $styles := pmf:parse-css($css)
    return
        map:new(($config, map:entry("styles", $styles)))
};

declare function pmf:parse-css($css as xs:string) {
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

declare %private function pmf:generate-css($root as document-node()) {
    string-join((
        for $rend in $root//tei:rendition[@xml:id][not(parent::tei:model)]
        return
            "&#10;.simple_" || $rend/@xml:id || " { " || 
            normalize-space($rend/string()) || " }",
        "&#10;",
        for $model in $root//tei:model[tei:rendition]
        let $spec := $model/ancestor::tei:elementSpec[1]
        let $count := count($spec//tei:model)
        for $rend in $model/tei:rendition
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
            "&#10;." || $class || " { " ||
            normalize-space($rend) || " }"
    ))
};

declare %private function pmf:filter-styles($styles as map(*)) {
    map:new(
        for $style in $styles?*[not(contains(., ":"))]
        let $mapped := $pmf:CSS_PROPERTIES($style)
        return
            if ($mapped) then
                map:entry($mapped, $styles($style))
            else
                ()
    )
};