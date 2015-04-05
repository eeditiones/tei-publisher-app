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
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <p>
    {
        attribute class { $class },
        pmf:apply-children($config, $node, $content)
    }
    </p>
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string, $content as node()*, $type, $subdiv) {
    let $level := count($content/ancestor::tei:div)
    return
        element { "h" || $level } {
            attribute class { $class },
            pmf:apply-children($config, $node, $content)
        }
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    if ($node/tei:label) then
        <dl class="{$class}">
        { $config?apply($config, $content) }
        </dl>
    else
        switch($node/@type)
            case "ordered" return
                <ol class="{$class}">{$config?apply($config, $content)}</ol>
            default return
                <ul class="{$class}">{$config?apply($config, $content)}</ul>
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    if ($node/preceding-sibling::tei:label) then (
        <dt>{$config?apply($config, $node/preceding-sibling::tei:label[1])}</dt>,
        <dd>{pmf:apply-children($config, $node, $content)}</dd>
    ) else
        <li class="{$class}">{pmf:apply-children($config, $node, $content)}</li>
};

declare function pmf:block($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <div class="{$class}">{pmf:apply-children($config, $node, $content)}</div>
};

declare function pmf:section($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <section class="{$class}">{pmf:apply-children($config, $node, $content)}</section>
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string, $id as item()*) {
    <span id="{$id}"/>
};

declare function pmf:link($config as map(*), $node as element(), $class as xs:string, $content as node()*, $url as xs:anyURI?) {
    <a href="{$url}">{pmf:apply-children($config, $node, $content)}</a>
};

declare function pmf:escapeChars($text as xs:string) {
    $text
};

declare function pmf:glyph($config as map(*), $node as element(), $class as xs:string, $content as xs:anyURI?) {
    if ($content = "char:EOLhyphen") then
        "&#xAD;"
    else
        ()
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string, $url as xs:anyURI,
    $width, $height, $scale) {
    let $style := if ($width) then "width: " || $width || "; " else ()
    let $style := if ($height) then $style || "height: " || $height || "; " else $style
    return
        <img src="{$url}">
        { if ($style) then attribute style { $style } else () }
        </img>
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string, $content as item()*, $place as xs:string?) {
    switch ($place)
        case "margin" return
            <div class="margin-note">
            { pmf:apply-children($config, $node, $content) }
            </div>
        default return
            <span class="label label-default note {$class}" data-toggle="popover" 
                data-content="{serialize(pmf:apply-children($config, $node, $content))}">
                {count($node/preceding::tei:note)}    
            </span>
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    <span class="{$class}">
    {
        pmf:apply-children($config, $node, $content)
    }
    </span>
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    string($content)
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:inline($config, $node, $class, $content)
};

declare function pmf:body($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <body class="{$class}">{pmf:apply-children($config, $node, $content)}</body>
};

declare function pmf:index($config as map(*), $node as element(), $class as xs:string, $content as node()*, $type as xs:string) {
    ()
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string, $type as xs:string, $label as item()*) {
    switch($type)
        case "page" return
            <span class="{$class}">{pmf:apply-children($config, $node, $label)}</span>
        default return
            <br/>
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <html class="{$class}">{pmf:apply-children($config, $node, $content)}</html>
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <head class="{$class}">{
        pmf:apply-children($config, $node, $content),
        if (exists($config?styles)) then
            $config?styles?* !
                <link rel="StyleSheet" type="text/css" href="{.}"/>
        else
            ()
    }</head>
};

declare function pmf:title($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <title>{pmf:apply-children($config, $node, $content)}</title>
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <table class="{$class}">{pmf:apply-children($config, $node, $content)}</table>
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <tr class="{$class}">{pmf:apply-children($config, $node, $content)}</tr>
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <td class="{$class}">
    {
        if ($node/@cols) then
            attribute colspan { $node/@cols }
        else
            (),
        if ($node/@rows) then
            attribute rowspan { $node/@rows }
        else
            ()
    }
    {
        pmf:apply-children($config, $node, $content)
    }
    </td>
};

declare function pmf:alternate($config as map(*), $node as element(), $class as xs:string, $option1 as node()*,
    $option2 as node()*) {
    <span class="alternate {$class}">
        <span>{pmf:apply-children($config, $node, $option1)}</span>
        <span class="hidden altcontent">{pmf:apply-children($config, $node, $option2)}</span>
    </span>
};

declare function pmf:match($config as map(*), $node as element(), $content as node()*) {
    <mark>{pmf:apply-children($config, $node, $content)}</mark>
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

declare function pmf:generate-css($root as document-node()) {
    string-join((
        "/* Generated stylesheet. Do not edit. */&#10;",
        "/* Generated from " || document-uri($root) || " */&#10;&#10;",
        "/* Global styles */&#10;",
        for $rend in $root//tei:rendition[@xml:id][not(parent::tei:model)]
        return
            "&#10;.simple_" || $rend/@xml:id || " { " || 
            normalize-space($rend/string()) || " }",
        "&#10;&#10;/* Model rendition styles */&#10;",
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

declare %private function pmf:apply-children($config as map(*), $node as element(), $content as item()*) {
    if ($node/@xml:id) then
        attribute id { $node/@xml:id }
    else
        (),
    $content ! (
        typeswitch(.)
            case element() return
                $config?apply($config, ./node())
            default return
                string(.)
    )
};

declare function pmf:escapeChars($text as item()) {
    $text
};