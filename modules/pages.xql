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
xquery version "3.0";

(:~ 
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "../content/odd2odd.xql";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";

declare variable $pages:app-root := request:get-context-path() || substring-after($config:app-root, "/db");

declare variable $pages:EXIDE := 
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");
        
declare
    %templates:wrap
    %templates:default("view", "div")
function pages:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?, $view as xs:string) {
    map {
        "data": pages:load-xml($view, $root, $doc)
    }
};

declare function pages:load-xml($view as xs:string, $root as xs:string?, $doc as xs:string) {
	if ($view = "div") then
        if ($root) then
            let $doc := doc($config:app-root || "/" || $doc)
            return 
                util:node-by-id($doc, $root)
        else
            let $div := (doc($config:app-root || "/" || $doc)//tei:div)[1]
            return
                if ($div) then
                    $div
                else
                    doc($config:app-root || "/" || $doc)/tei:TEI//tei:body
    else
        doc($config:app-root || "/" || $doc)/tei:TEI/tei:text
};

declare function pages:back-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/index.html?odd=" || $odd
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:pdf-link($node as node(), $model as map(*), $odd as xs:string, $source as xs:boolean?) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/modules/fo.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root)
            || (if ($source) then "&amp;source=yes" else ())
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:latex-link($node as node(), $model as map(*), $odd as xs:string, $source as xs:boolean?) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/modules/latex.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root)
            || (if ($source) then "&amp;source=yes" else ())
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:epub-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { $pages:app-root || "/modules/get-epub.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root) },
        $node/node()
    }
};

declare function pages:single-page-link($node as node(), $model as map(*), $odd as xs:string, $doc as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "?view=plain&amp;odd=" || $odd },
        $node/node()
    }
};

declare function pages:xml-link($node as node(), $model as map(*), $doc as xs:string) {
    let $doc-path := $config:app-root || $doc
    let $eXide-link := $pages:EXIDE || "?open=" || $doc-path
    let $rest-link := '/exist/rest' || $doc-path
    return
        element { node-name($node) } {
            $node/@* except ($node/@href, $node/@class),
            if ($pages:EXIDE)
            then (
                attribute href { $eXide-link },
                attribute data-exide-open { $doc-path },
                attribute class { "eXide-open " || $node/@class },
                attribute target { "eXide" }
            ) else (
                attribute href { $rest-link },
                attribute target { "_blank" }
            ),
            $node/node()
        }
};

declare 
    %templates:default("view", "div")
function pages:view($node as node(), $model as map(*), $odd as xs:string, $view as xs:string) {
    let $xml := 
        if ($view = "div") then
            pages:get-content($model("data"))
        else
            $model?data//*:body/*
    return
        pages:process-content($odd, $xml)
};

declare function pages:process-content($odd as xs:string, $xml as element()*) {
	let $html :=
        pmu:process(odd:get-compiled($config:odd-root, $odd, $config:compiled-odd-root), $xml, $config:output-root, "web", "../generated", $config:module-config)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    return
        <div class="content {$class}">
        {$html}
        </div>
};

declare
    %templates:wrap
function pages:table-of-contents($node as node(), $model as map(*), $odd as xs:string) {
    pages:toc-div(root($model?data), $odd)
};

declare %private function pages:toc-div($node, $odd as xs:string) {
    let $divs := $node//tei:div[empty(ancestor::tei:div) or ancestor::tei:div[1] is $node][tei:head]
    return
        <ul>
        {
            for $div in $divs
            let $html := for-each($div/tei:head//text(), function($node) {
                if ($node/(ancestor::tei:note|ancestor::tei:reg|ancestor::tei:sic)) then
                    ()
                else
                    $node
            })
            return
                <li>
                    <a class="toc-link" href="{util:document-name($div)}?root={util:node-id($div)}&amp;odd={$odd}">{$html}</a>
                    {pages:toc-div($div, $odd)}
                </li>
        }
        </ul>
};

declare
    %templates:wrap
function pages:styles($node as node(), $model as map(*), $odd as xs:string?) {
    attribute href {
        let $name := replace($odd, "^([^/\.]+).*$", "$1")
        return
            $pages:app-root || "/" || $config:output || "/" || $name || ".css"
    }
};

declare 
    %templates:wrap
    %templates:default("view", "div")
function pages:navigation($node as node(), $model as map(*), $view as xs:string) {
    let $div := $model("data")
    let $work := $div/ancestor-or-self::tei:TEI
    return
        if ($view = "single") then
            map {
                "div" : $div,
                "work" : $work
            }
        else
            let $parent := $div/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
            let $prevDiv := $div/preceding::tei:div[1]
            let $prevDiv := pages:get-previous(if ($parent and (empty($prevDiv) or $div/.. >> $prevDiv)) then $div/.. else $prevDiv)
            let $nextDiv := pages:get-next($div)
        (:        ($div//tei:div[not(*[1] instance of element(tei:div))] | $div/following::tei:div)[1]:)
            return
                map {
                    "previous" : $prevDiv,
                    "next" : $nextDiv,
                    "work" : $work,
                    "div" : $div
                }
};

declare function pages:get-next($div as element()) {
    if ($div/tei:div) then
        if (count(($div/tei:div[1])/preceding-sibling::*) < 5) then
            pages:get-next($div/tei:div[1])
        else
            $div/tei:div[1]
    else
        $div/following::tei:div[1]
};

declare function pages:get-previous($div as element(tei:div)?) {
    if (empty($div)) then
        ()
    else
        if (
            empty($div/preceding-sibling::tei:div)  (: first div in section :)
            and count($div/preceding-sibling::*) < 5 (: less than 5 elements before div :)
            and $div/.. instance of element(tei:div) (: parent is a div :)
        ) then
            pages:get-previous($div/..)
        else
            $div
};

declare function pages:get-content($div as element()) {
    if ($div instance of element(tei:teiHeader)) then 
        $div
    else
        if ($div instance of element(tei:div)) then
            if ($div/tei:div) then
                if (count(($div/tei:div[1])/preceding-sibling::*) < 5) then
                    let $child := $div/tei:div[1]
                    return
                        element { node-name($div) } {
                            $div/@*,
                            $child/preceding-sibling::*,
                            pages:get-content($child)
                        }
                else
                    element { node-name($div) } {
                        $div/@*,
                        $div/tei:div[1]/preceding-sibling::*
                    }
            else
                $div
        else 
            $div
};

declare
    %templates:wrap
function pages:navigation-title($node as node(), $model as map(*)) {
    pages:title($model('data')/ancestor-or-self::tei:TEI)
};

declare function pages:title($work as element()) {
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()
    return
        if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
};

declare
    %templates:default("view", "div")
function pages:navigation-link($node as node(), $model as map(*), $direction as xs:string, $odd as xs:string, $view as xs:string) {
    if ($view = "single") then
        ()
    else if ($model($direction)) then
        <a data-doc="{util:document-name($model($direction))}"
            data-root="{util:node-id($model($direction))}"
            data-current="{util:node-id($model('div'))}"
            data-odd="{$odd}">
        {
            $node/@* except $node/@href,
            let $id := util:document-name($model($direction)) || "?root=" || util:node-id($model($direction)) || "&amp;odd=" || $odd
            return
                attribute href { $id },
            $node/node()
        }
        </a>
    else
        <a href="#" style="visibility: hidden;">{$node/@class, $node/node()}</a>
};

declare
    %templates:wrap
function pages:app-root($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute data-app { request:get-context-path() || substring-after($config:app-root, "/db") },
        templates:process($node/*, $model)
    }
};