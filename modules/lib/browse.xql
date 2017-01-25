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
xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %templates:wrap
function app:show-for-document($node as node(), $model as map(*), $doc as xs:string?, $query as xs:string?, $start as xs:string?) {
    if ($doc and empty($query) and empty($start)) then
        templates:process($node/*, $model)
    else
        ()
};


declare
    %templates:wrap
function app:check-login($node as node(), $model as map(*)) {
    let $user := request:get-attribute($config:login-domain || ".user")
    return
        if ($user) then
            templates:process($node/*[2], $model)
        else
            templates:process($node/*[1], $model)
};

declare
    %templates:wrap
function app:current-user($node as node(), $model as map(*)) {
    request:get-attribute($config:login-domain || ".user")
};

declare
    %templates:wrap
function app:show-if-logged-in($node as node(), $model as map(*)) {
    let $user := request:get-attribute($config:login-domain || ".user")
    return
        if ($user) then
            templates:process($node/node(), $model)
        else
            ()
};

(:~
 : List documents in data collection
 :)
declare
    %templates:wrap
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $root as xs:string,
    $browse as xs:string?) {
    let $cached := session:get-attribute("simple.works")
    let $filtered :=
        if ($filter) then
            let $ordered :=
                for $rootCol in $config:data-root
                for $item in
                    ft:search($rootCol || "/" || $root, $browse || ":" || $filter, ("author", "title"))/search
                let $author := $item/field[@name = "author"]
                order by $author[1], $author[2], $author[3]
                return
                    $item
            for $doc in $ordered
            return
                doc($doc/@uri)/tei:TEI
        else if ($cached and $filter != "") then
            $cached
        else
            $config:data-root ! collection(. || "/" || $root)/tei:TEI
    return (
        session:set-attribute("simple.works", $filtered),
        session:set-attribute("browse", $browse),
        session:set-attribute("filter", $filter),
        map {
            "all" : $filtered,
            "mode": "browse"
        }
    )
};

declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:browse($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $filter as xs:string?) {
    if (empty($model?all) and (empty($filter) or $filter = "")) then
        templates:process($node/*[@class="empty"], $model)
    else
        subsequence($model?all, $start, $per-page) !
            templates:process($node/*[not(@class="empty")], map:new(
                ($model, map {
                    "work": .,
                    "config": tpu:parse-pi(root(.), ())
                }))
            )
};

declare
    %templates:wrap
function app:short-header($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $relPath := config:get-identifier($work)
    return
        $pm-config:web-transform($work/tei:teiHeader, map {
            "header": "short",
            "doc": $relPath || "?odd=" || $model?config?odd
        }, $model?config?odd)
};

(:~
 : Create a bootstrap pagination element to navigate through the hits.
 :)
declare
    %templates:default('key', 'hits')
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function app:paginate($node as node(), $model as map(*), $key as xs:string, $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
    if ($min-hits < 0 or count($model($key)) >= $min-hits) then
        element { node-name($node) } {
            $node/@*,
            let $count := xs:integer(ceiling(count($model($key))) div $per-page) + 1
            let $middle := ($max-pages + 1) idiv 2
            return (
                if ($start = 1) then (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-backward"/></a>
                    </li>
                ) else (
                    <li>
                        <a href="?start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li>
                        <a href="?start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                    </li>
                ),
                let $startPage := xs:integer(ceiling($start div $per-page))
                let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
                let $upperBound := min(($lowerBound + $max-pages - 1, $count))
                let $lowerBound := max(($upperBound - $max-pages + 1, 1))
                for $i in $lowerBound to $upperBound
                return
                    if ($i = ceiling($start div $per-page)) then
                        <li class="active"><a href="?start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                    else
                        <li><a href="?start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
                if ($start + $per-page < count($model($key))) then (
                    <li>
                        <a href="?start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a href="?start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                ) else (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                )
            )
        }
    else
        ()
};

(:~
    Create a span with the number of items in the current search result.
:)
declare
    %templates:wrap
    %templates:default("key", "hitCount")
function app:hit-count($node as node()*, $model as map(*), $key as xs:string) {
    let $value := $model?($key)
    return
        if ($value instance of xs:integer) then
            $value
        else
            count($value)
};

(:~
 :
 :)
declare function app:work-title($node as node(), $model as map(*), $type as xs:string?) {
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $id := util:document-name($work)
    return
        <a href="{$node/@href}{$id}{$suffix}">{ app:work-title($work) }</a>
};

declare function app:work-title($work as element(tei:TEI)?) {
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()
    let $main-title := if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
    return
        $main-title
};

declare function app:download-link($node as node(), $model as map(*), $type as xs:string,
    $doc as xs:string?, $source as xs:boolean?, $mode as xs:string?, $odd as xs:string?) {
    let $file :=
        if ($model?work) then
            config:get-identifier($model?work)
        else
            $doc
    let $file :=
        if ($doc) then
            replace($file, "^.*?([^/]*)$", "$1")
        else
            $file
    let $uuid := util:uuid()
    return
        element { node-name($node) } {
            $node/@*,
            attribute data-token { $uuid },
            attribute href { $node/@href || $file || "." || $type || "?token=" || $uuid || "&amp;cache=no"
                || "&amp;odd=" || ($model?config?odd, $config:odd)[1]
                || (if ($source) then "&amp;source=yes" else ()) || (if ($mode) then "&amp;mode=" || $mode else ())
            },
            $node/node()
        }
};

declare function app:recompile-link($node as node(), $model as map(*)) {
    let $odd :=
        if ($model?work) then
            ($model?config?odd, $config:odd)[1]
        else
            $config:odd
    return
        element { node-name($node) } {
            $node/@*,
            attribute href { "?source=" || $odd },
            $node/node()
        }
};

declare
    %templates:wrap
function app:fix-links($node as node(), $model as map(*)) {
    app:fix-links(templates:process($node/node(), $model))
};

declare function app:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(a) | element(link) return
                (: skip links with @data-template attributes; otherwise we can run into duplicate @href errors :)
                if ($node/@data-template) then
                    $node
                else
                    let $href :=
                        replace(
                            $node/@href,
                            "\$app",
                            (request:get-context-path() || substring-after($config:app-root, "/db"))
                        )
                    return
                        element { node-name($node) } {
                            attribute href {$href}, $node/@* except $node/@href, app:fix-links($node/node())
                        }
            case element() return
                element { node-name($node) } {
                    $node/@*, app:fix-links($node/node())
                }
            default return
                $node
};
