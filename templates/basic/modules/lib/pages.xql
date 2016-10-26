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
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace search="http://www.tei-c.org/tei-simple/search" at "search.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

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
function pages:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
    $id as xs:string?, $view as xs:string?) {
    let $doc := xmldb:decode($doc)
    let $view := if ($view) then $view else $config:default-view
    let $node :=
        if ($id) then
            let $node := doc($config:data-root || "/" || $doc)/id($id)
            let $div := $node/ancestor-or-self::tei:div[1]
            return
                if (empty($div)) then
                    $node/following-sibling::tei:div[1]
                else
                    $div
        else
            pages:load-xml($view, $root, $doc)
    let $node :=
        if ($node) then
            $node
        else
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <teiHeader>
                    <fileDesc>
                        <titleStmt>
                            <title>Not found</title>
                        </titleStmt>
                    </fileDesc>
                </teiHeader>
                <text>
                    <body>
                        <div>
                            <head>Failed to load!</head>
                            <p>Could not load document {$doc}. Maybe it is not valid TEI or not in the TEI namespace?</p>
                        </div>
                    </body>
                </text>
            </TEI>//tei:div
    return
        map {
            "data": $node
        }
};

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $view := if ($view) then $view else $config:default-view
    return
        switch ($view)
    	    case "div" return
        	    if (matches($doc, "_\d+\.?[\d\.]*\.xml$")) then
                    let $analyzed := analyze-string($doc, "^(.*)_(\d+\.?[\d\.]*)\.xml$")
                    let $docName := $analyzed//fn:group[@nr = 1]/text()
                    return
                        util:node-by-id(pages:get-document($docName), $analyzed//fn:group[@nr = 2]/string())
                else if ($root) then
                    let $node := util:node-by-id(pages:get-document($doc), $root)
                    return
                        $node/ancestor-or-self::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1]
                else
                    let $div := (pages:get-document($doc)//tei:div)[1]
                    return
                        if ($div) then
                            $div
                        else
                            let $group := pages:get-document($doc)/tei:TEI/tei:text/tei:group/tei:text/(tei:front|tei:body|tei:back)
                            return
                                if ($group) then
                                    $group[1]
                                else
                                    pages:get-document($doc)/tei:TEI//tei:body
            case "page" return
                if (matches($doc, "_\d+\.[\d\.]+\.xml$")) then
                    let $analyzed := analyze-string($doc, "^(.*)_(\d+\.[\d\.]+)\.xml$")
                    let $docName := $analyzed//fn:group[@nr = 1]/text()
                    let $targetNode := util:node-by-id(pages:get-document($docName), $analyzed//fn:group[@nr = 2]/string())
                    return
                        $targetNode
                else if ($root) then
                    util:node-by-id(pages:get-document($doc), $root)
                else
                    let $div := (pages:get-document($doc)//tei:pb)[1]
                    return
                        if ($div) then
                            $div
                        else
                            pages:get-document($doc)/tei:TEI//tei:body
            default return
                if ($root) then
                    util:node-by-id(pages:get-document($doc), $root)
                else
                    pages:get-document($doc)/tei:TEI/tei:text
};

declare function pages:get-document($idOrName as xs:string) {
    if ($config:address-by-id) then
        root(collection($config:data-root)/id($idOrName))
    else
        doc($config:data-root || "/" || $idOrName)
};

declare function pages:back-link($node as node(), $model as map(*)) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/works/"
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:single-page-link($node as node(), $model as map(*), $doc as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "?view=plain&amp;odd=" || $config:odd },
        $node/node()
    }
};

declare function pages:xml-link($node as node(), $model as map(*), $source as xs:string?) {
    let $doc-path :=
        if ($source = "odd") then
            $config:odd-root || "/" || $config:odd
        else if ($model?work) then
            document-uri(root($model?work))
        else if ($model?data) then
            document-uri(root($model?data))
        else
            $config:app-root || "/" || $source
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
    %templates:default("action", "browse")
function pages:view($node as node(), $model as map(*), $view as xs:string?, $action as xs:string) {
    let $view := pages:determine-view($view, $model?data)
    let $data :=
        if ($action = "search") then
            let $query := session:get-attribute("apps.simple.query")
            let $div :=
                if ($model?data instance of element(tei:pb)) then
                    let $nextPage := $model?data/following::tei:pb[1]
                    return
                        if ($nextPage) then
                            ($model?data/ancestor::* intersect $nextPage/ancestor::*)[last()]
                        else
                            ($model?data/ancestor::tei:div, $model?data/ancestor::tei:body)[1]
                else
                    $model?data
            let $expanded :=
                util:expand(
                    (
                        search:query-default-view($div, $query),
                        $div[.//tei:head[ft:query(., $query)]]
                    ), "add-exist-id=all"
                )
            return
                if ($model?data instance of element(tei:pb)) then
                    $expanded//tei:pb[@exist:id = util:node-id($model?data)]
                else
                    $expanded
        else
            $model?data
    let $xml :=
        if ($view = ("div", "page", "body")) then
            pages:get-content($data[1])
        else
            $model?data//*:body/*
    return
        pages:process-content($xml, $model?data)
};

declare function pages:process-content($xml as element()*, $root as element()*) {
	let $html := $pm-config:web-transform($xml, map { "root": $root })
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    let $body := pages:clean-footnotes($html)
    return
        <div class="{$config:css-content-class} {$class}">
        {
            $body,
            if ($html//li[@class="footnote"]) then
                <div class="footnotes">
                    <ol>
                    {
                        for $note in $html//li[@class="footnote"]
                        order by number($note/@value)
                        return
                            $note
                    }
                    </ol>
                </div>
            else
                ()
        }
        </div>
};

declare function pages:clean-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(li) return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        pages:clean-footnotes($node/node())
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    pages:clean-footnotes($node/node())
                }
            default return
                $node
};

declare
    %templates:wrap
function pages:table-of-contents($node as node(), $model as map(*), $view as xs:string?) {
    pages:toc-div(root($model?data), $view)
};

declare %private function pages:toc-div($node, $view as xs:string?) {
    let $view := pages:determine-view($view, $node)
    let $divs := $node//tei:div[tei:head] except $node//tei:div[tei:head]//tei:div
(:    let $divs := $node//tei:div[empty(ancestor::tei:div) or ancestor::tei:div[1] is $node][tei:head]:)
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
            let $root := (
                if ($view = "page") then
                    ($div/*[1][self::tei:pb], $div/preceding::tei:pb[1])[1]
                else
                    (),
                $div
            )[1]
            return
                <li>
                    <a class="toc-link" href="{util:document-name($div)}?root={util:node-id($root)}&amp;odd={$config:odd}">{$html}</a>
                    {pages:toc-div($div, $view)}
                </li>
        }
        </ul>
};

declare
    %templates:wrap
function pages:styles($node as node(), $model as map(*)) {
    attribute href {
        let $name := replace($config:odd, "^([^/\.]+).*$", "$1")
        return
            $pages:app-root || "/" || $config:output || "/" || $name || ".css"
    }
};

declare
    %templates:wrap
function pages:navigation($node as node(), $model as map(*), $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $div := $model?data
    let $work := $div/ancestor-or-self::tei:TEI
    let $map := map {
        "div" : $div,
        "work" : $work
    }
    return
        if ($view = "single") then
            $map
        else
            map:merge(($map, map {
                "previous": $config:previous-page($div, $view),
                "next": $config:next-page($div, $view)
            }))
};

declare function pages:get-next($div as element(), $view as xs:string) {
    switch ($view)
        case "page" return
            $div/following::tei:pb[1]
        case "body" return
            ($div/following-sibling::*, $div/../following-sibling::*)[1]
        default return
            pages:get-next($div)
};


declare function pages:get-next($div as element()) {
    if ($div/tei:div[count(ancestor::tei:div) < $config:pagination-depth]) then
        if ($config:pagination-fill > 0 and count(($div/tei:div[1])/preceding-sibling::*) < $config:pagination-fill) then
            pages:get-next($div/tei:div[1])
        else
            $div/tei:div[1]
    else
        $div/following::tei:div[1][count(ancestor::tei:div) < $config:pagination-depth]
};

declare function pages:get-previous($div as element(), $view as xs:string) {
    switch ($view)
        case "page" return
            $div/preceding::tei:pb[1]
        case "body" return
            ($div/preceding-sibling::*, $div/../preceding-sibling::*)[1]
        default return
            pages:get-previous($div)
};


declare function pages:get-previous($div as element()) {
    let $parent := $div/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
    let $prevDiv := $div/preceding::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1]
    return
        pages:get-previous-recursive(
            if ($parent and (empty($prevDiv) or $div/.. >> $prevDiv)) then $div/.. else $prevDiv
        )
};

declare function pages:get-previous-recursive($div as element(tei:div)?) {
    if (empty($div)) then
        ()
    else
        if (
            empty($div/preceding-sibling::tei:div)  (: first div in section :)
            and $config:pagination-fill > 0
            and count($div/preceding-sibling::*) < $config:pagination-fill (: less than 5 elements before div :)
            and $div/.. instance of element(tei:div) (: parent is a div :)
        ) then
            pages:get-previous-recursive($div/ancestor::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1])
        else
            $div
};

declare function pages:get-content($div as element()) {
    typeswitch ($div)
        case element(tei:teiHeader) return
            $div
        case element(tei:pb) return (
            let $nextPage := $div/following::tei:pb[1]
            let $chunk :=
                pages:milestone-chunk($div, $nextPage,
                    if ($nextPage) then
                        ($div/ancestor::* intersect $nextPage/ancestor::*)[last()]
                    else
                        ($div/ancestor::tei:div, $div/ancestor::tei:body)[1]
                )
            return
                $chunk
        )
        case element(tei:div) return
            if ($div/tei:div and count($div/ancestor::tei:div) < $config:pagination-depth - 1) then
                if ($config:pagination-fill > 0 and count(($div/tei:div[1])/preceding-sibling::*) < $config:pagination-fill) then
                    let $child := $div/tei:div[1]
                    return
                        element { node-name($div) } {
                            $div/@* except $div/@exist:id,
                            attribute exist:id { util:node-id($div) },
                            util:expand(($child/preceding-sibling::*, $child), "add-exist-id=all")
                        }
                else
                    element { node-name($div) } {
                        $div/@* except $div/@exist:id,
                        attribute exist:id { util:node-id($div) },
                        util:expand($div/tei:div[1]/preceding-sibling::*, "add-exist-id=all")
                    }
            else
                $div
        default return
            $div
};

declare %private function pages:milestone-chunk($ms1 as element(), $ms2 as element()?, $node as node()*) as node()*
{
    typeswitch ($node)
        case element() return
            if ($node is $ms1) then
                util:expand($node, "add-exist-id=all")
            else if ( some $n in $node/descendant::* satisfies ($n is $ms1 or $n is $ms2) ) then
                element { node-name($node) } {
                    $node/@*,
                    for $i in ( $node/node() )
                    return pages:milestone-chunk($ms1, $ms2, $i)
                }
            else if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then
                util:expand($node, "add-exist-id=all")
            else
                ()
        case attribute() return
            $node (: will never match attributes outside non-returned elements :)
        default return
            if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then $node
            else ()
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

declare function pages:navigation-link($node as node(), $model as map(*), $direction as xs:string, $view as xs:string?) {
    let $view := if ($view) then $view else $config:default-view
    return
        if ($view = "single") then
            ()
        else if ($model($direction)) then
            let $doc :=
                config:get-identifier($model($direction))
            return
                <a data-doc="{$doc}"
                    data-root="{util:node-id($model($direction))}"
                    data-current="{util:node-id($model('div'))}"
                    data-odd="{$config:odd}">
                {
                    $node/@* except $node/@href,
                    let $id := $doc || "?root=" || util:node-id($model($direction))
                        || "&amp;odd=" || $config:odd || "&amp;view=" || $view
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

declare function pages:determine-view($view as xs:string?, $node as node()) {
    typeswitch ($node)
        case element(tei:body) return
            "body"
        case element(tei:front) return
            "body"
        case element(tei:back) return
            "body"
        default return
            if ($view) then $view else $config:default-view
};

declare function pages:switch-view($node as node(), $model as map(*), $root as xs:string?, $doc as xs:string, $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $targetView := if ($view = "page") then "div" else "page"
    let $root := pages:switch-view-id($model?data, $view)
    return
        element { node-name($node) } {
            $node/@* except $node/@class,
            if (pages:has-pages($model?data) and $root) then (
                attribute href {
                    "?root=" || util:node-id($root) || "&amp;odd=" || $config:odd || "&amp;view=" || $targetView
                },
                if ($view = "page") then (
                    attribute aria-pressed { "true" },
                    attribute class { $node/@class || " active" }
                ) else
                    $node/@class
            ) else (
                $node/@class,
                attribute disabled { "disabled" }
            ),
            templates:process($node/node(), $model)
        }
};

declare function pages:has-pages($data as element()+) {
    exists((root($data)//(tei:div|tei:body))[1]//tei:pb)
};

declare function pages:switch-view-id($data as element()+, $view as xs:string) {
    let $root :=
        if ($view = "div") then
            ($data/*[1][self::tei:pb], $data/preceding::tei:pb[1])[1]
        else
            $data/ancestor::tei:div[1]
    return
        $root
};
