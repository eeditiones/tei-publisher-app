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

declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string+, $content) {
    <p class="{$class}">
    {
        pmf:apply-children($config, $node, $content)
    }
    </p>
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $level := 
        if ($content instance of element()) then
            max((count($content/ancestor::tei:div), 1))
        else
            4
    return
        element { "h" || $level } {
            attribute class { $class },
            pmf:apply-children($config, $node, $content)
        }
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string+, $content) {
    if ($node/tei:label) then
        <dl class="{$class}">
        { pmf:apply-children($config, $node, $content) }
        </dl>
    else
        switch($node/@type)
            case "ordered" return
                <ol class="{$class}">{pmf:apply-children($config, $node, $content)}</ol>
            default return
                <ul class="{$class}">{pmf:apply-children($config, $node, $content)}</ul>
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string+, $content) {
    if ($node/preceding-sibling::tei:label) then (
        <dt>{pmf:apply-children($config, $node, $node/preceding-sibling::tei:label[1])}</dt>,
        <dd>{pmf:apply-children($config, $node, $content)}</dd>
    ) else
        <li class="{$class}">{pmf:apply-children($config, $node, $content)}</li>
};

declare function pmf:block($config as map(*), $node as element(), $class as xs:string+, $content) {
    <div class="{$class}">{pmf:apply-children($config, $node, $content)}</div>
};

declare function pmf:section($config as map(*), $node as element(), $class as xs:string+, $content) {
    <section class="{$class}">{pmf:apply-children($config, $node, $content)}</section>
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string+, $content, $id as item()*) {
    <span id="{$id}"/>
};

declare function pmf:link($config as map(*), $node as element(), $class as xs:string+, $content, $link as item()?) {
    <a href="{$link}" class="{$class}">{pmf:apply-children($config, $node, $content)}</a>
};

declare function pmf:escapeChars($text as item()*) {
    typeswitch($text)
        case attribute() return
            data($text)
        default return
            $text
};

declare function pmf:glyph($config as map(*), $node as element(), $class as xs:string+, $content) {
    if ($content = "char:EOLhyphen") then
        "&#xAD;"
    else
        ()
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string+, $content, $url as xs:anyURI,
    $width, $height, $scale, $title) {
    let $style := if ($width) then "width: " || $width || "; " else ()
    let $style := if ($height) then $style || "height: " || $height || "; " else $style
    return
        if ($title) then
            <figure>
                <img src="{$url}">
                { if ($style) then attribute style { $style } else () }
                </img>
                <figcaption>{pmf:apply-children($config, $node, $title)}</figcaption>
            </figure>
        else
            <img src="{$url}">
            { if ($style) then attribute style { $style } else () }
            </img>
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content, $place, $label) {
    switch ($place)
        case "margin" return
            if ($label) then (
                <span class="margin-note-ref">{$label}</span>,
                <span class="margin-note">
                    <span class="n">{$label/string()}) </span>{ $config?apply-children($config, $node, $content) }
                </span>
            ) else
                <span class="margin-note">
                { pmf:apply-children($config, $node, $content) }
                </span>
        default return
            <span class="label label-default note {$class}" data-toggle="popover" 
                data-content="{serialize(<div>{$config?apply-children($config, $node, $content/node())}</div>)}">
                {
                    if ($label) then
                        $label
                    else
                        count($node/preceding::tei:note) + 1
                }
            </span>
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string+, $content) {
    <span class="{$class}">
    {
        $config?apply-children($config, $node, $content)
    }
    </span>
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string+, $content) {
    string-join($content)
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:inline($config, $node, $class, $content)
};

declare function pmf:body($config as map(*), $node as element(), $class as xs:string+, $content) {
    <body class="{$class}">{pmf:apply-children($config, $node, $content)}</body>
};

declare function pmf:index($config as map(*), $node as element(), $class as xs:string+, $type, $content) {
    ()
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string+, $content) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string+, $content, $type as xs:string, $label as item()*) {
    switch($type)
        case "page" return
            <span class="{$class}">{pmf:apply-children($config, $node, $label)}</span>
        default return
            <br/>
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string+, $content) {
    <html class="{$class}">{pmf:apply-children($config, $node, $content)}</html>
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string+, $content) {
    <head class="{$class}">{
        pmf:apply-children($config, $node, $content),
        if (exists($config?styles)) then
            $config?styles?* !
                <link rel="StyleSheet" type="text/css" href="{.}"/>
        else
            ()
    }</head>
};

declare function pmf:title($config as map(*), $node as element(), $class as xs:string+, $content) {
    <title>{pmf:apply-children($config, $node, $content)}</title>
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string+, $content) {
    <table class="{$class}">{pmf:apply-children($config, $node, $content)}</table>
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string+, $content) {
    <tr class="{$class}">{pmf:apply-children($config, $node, $content)}</tr>
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string+, $content) {
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

declare function pmf:alternate($config as map(*), $node as element(), $class as xs:string+, $content, $default as node()*,
    $alternate as node()*) {
    <span class="alternate {$class}">
        <span>{pmf:apply-children($config, $node, $default)}</span>
        <span class="altcontent">{pmf:apply-children($config, $node, $alternate)}</span>
    </span>
};

declare function pmf:match($config as map(*), $node as element(), $content) {
    <mark>{pmf:apply-children($config, $node, $content)}</mark>
};

declare function pmf:apply-children($config as map(*), $node as element(), $content) {
    if ($node/@xml:id) then
        attribute id { $node/@xml:id }
    else
        (),
    $config?apply-children($config, $node, $content)
};