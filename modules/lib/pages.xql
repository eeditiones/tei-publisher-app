(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
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
    let $data :=
        if ($id) then
            let $node := doc($config:data-root || "/" || $doc)/id($id)
            let $div := $node/ancestor-or-self::tei:div[1]
            let $config := tpu:parse-pi(root($node), $view)
            return
                map {
                    "config": $config,
                    "data":
                        if (empty($div)) then
                            $node/following-sibling::tei:div[1]
                        else
                            $div
                }
        else
            pages:load-xml($view, $root, $doc)
    let $node :=
        if ($data?data) then
            $data?data
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
            "config": $data?config,
            "data": $node
        }
};

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $data := pages:get-document($doc)
    let $config := tpu:parse-pi(root($data), $view)
    return
        map {
            "config": $config,
            "data":
                switch ($config?view)
            	    case "div" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return
                                $node/ancestor-or-self::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1]
                        else
                            let $div := ($data//tei:div)[1]
                            return
                                if ($div) then
                                    $div
                                else
                                    let $group := $data/tei:TEI/tei:text/tei:group/tei:text/(tei:front|tei:body|tei:back)
                                    return
                                        if ($group) then
                                            $group[1]
                                        else
                                            $data/tei:TEI//tei:body
                    case "page" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            let $div := ($data//tei:pb)[1]
                            return
                                if ($div) then
                                    $div
                                else
                                    $data/tei:TEI//tei:body
                    default return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data/tei:TEI/tei:text
        }
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
        else if ($source) then
            $config:app-root || "/" || $source
        else if ($model?work) then
            document-uri(root($model?work))
        else if ($model?data) then
            document-uri(root($model?data))
        else
            ()
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
function pages:view($node as node(), $model as map(*), $action as xs:string) {
    let $view := pages:determine-view($model?config?view, $model?data)
    let $data :=
        if ($action = "search" and exists(session:get-attribute("apps.simple.query"))) then
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
            pages:get-content($model?config, $data[1])
        else
            $model?data//*:body/*
    return
        pages:process-content($xml, $model?data, $model?config?odd)
};

declare function pages:process-content($xml as element()*, $root as element()*, $odd as xs:string) {
	let $html := $pm-config:web-transform($xml, map { "root": $root }, $odd)
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
function pages:table-of-contents($node as node(), $model as map(*)) {
    console:log($model?data/preceding::tei:div[last()]/tei:head),
    let $current :=
        if ($model?config?view = "page") then
            ($model?data/ancestor-or-self::tei:div[1], $model?data/following::tei:div[1])[1]
        else
            $model?data
    return
        pages:toc-div(root($model?data), $model?config?view, $current, $model?config?odd)
};

declare %private function pages:toc-div($node, $view as xs:string?, $current as element(), $odd as xs:string) {
    let $view := pages:determine-view($view, $node)
    let $divs := $node//tei:div[tei:head] except $node//tei:div[tei:head]//tei:div
    return
        <ul>
        {
            for $div in $divs
            let $html :=
                if ($div/tei:head/*) then
                    $pm-config:web-transform($div/tei:head, map { "header": "short", "root": $div }, $odd)
                else
                    $div/tei:head/text()
            let $root := (
                if ($view = "page") then
                    ($div/*[1][self::tei:pb], $div/preceding::tei:pb[1])[1]
                else
                    (),
                $div
            )[1]
            let $id := "T" ||util:uuid()
            let $hasDivs := exists($div//tei:div[tei:head] except $div//tei:div[tei:head]//tei:div)
            let $isIn := if ($div/descendant::tei:div[. is $current]) then "in" else ()
            let $isCurrent := if ($div is $current) then "active" else ()
            let $icon := if ($isIn) then "expand_less" else "expand_more"
            return
                <li>
                    {
                        if ($hasDivs) then
                            <a data-toggle="collapse" href="#{$id}"><span class="material-icons">{$icon}</span></a>
                        else
                            ()
                    }
                    <a data-doc="{config:get-identifier($div)}" data-div="{util:node-id($div)}" class="toc-link {$isCurrent}"
                        href="{util:document-name($div)}?root={util:node-id($root)}&amp;odd={$odd}&amp;view={$view}">{$html}</a>
                    {
                        if ($hasDivs) then
                            <div id="{$id}" class="collapse {$isIn}">{pages:toc-div($div, $view, $current, $odd)}</div>
                        else
                            pages:toc-div($div, $view, $current, $odd)
                    }
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
                "previous": $config:previous-page($model?config, $div, $view),
                "next": $config:next-page($model?config, $div, $view)
            }))
};

declare function pages:get-content($config as map(*), $div as element()) {
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
            if ($div/tei:div and count($div/ancestor::tei:div) < $config?depth - 1) then
                if ($config?fill > 0 and
                    count(($div/tei:div[1])/preceding-sibling::*//*) < $config?fill) then
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
                        console:log("showing preceding siblings of next div child"),
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

declare function pages:navigation-link($node as node(), $model as map(*), $direction as xs:string) {
        if ($model?config?view = "single") then
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
                        || "&amp;odd=" || $config:odd || "&amp;view=" || $model?config?view
                    return
                        attribute href { $id },
                    $node/node()
                }
                </a>
        else
            let $doc :=
                config:get-identifier($model?data)
            return
                <a href="#" style="visibility: hidden;"
                    data-doc="{$doc}">{$node/@class, $node/node()}</a>
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
