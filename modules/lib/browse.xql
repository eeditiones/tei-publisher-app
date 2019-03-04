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
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";

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
function app:sort($items as element()*, $sortBy as xs:string?) {
    let $items :=
        if (count($config:data-exclude) = 1) then
            $items[not(matches(util:collection-name(.), $config:data-exclude))]
        else
            $items
    return
        if ($sortBy) then
            for $item in $items
            let $field := ft:get-field(document-uri(root($item)), $sortBy)
            let $content :=
                if (exists($field)) then
                    $field
                else
                    let $data := nav:get-metadata(map { "type": nav:document-type($item) }, $item, $sortBy)
                    return
                        replace(string-join($data, " "), "^\s*(.*)$", "$1", "m")
            order by $content
            return
                $item
        else
            $items
};


(:~
 : List documents in data collection
 :)
declare
    %templates:wrap
    %templates:default("sort", "title")
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $root as xs:string,
    $browse as xs:string?, $odd as xs:string?, $sort as xs:string) {
    let $odd := ($odd, session:get-attribute("teipublisher.odd"))[1]
    let $oddAvailable := $odd and doc-available($config:odd-root || "/" || $odd)
    let $odd := if ($oddAvailable) then $odd else $config:default-odd
    let $cached := session:get-attribute("teipublisher.works")
    let $filtered :=
        if (exists($filter)) then
            query:query-metadata($browse, $filter)
        else if (exists($cached) and $filter = session:get-attribute("teipublisher.filter")) then
            $cached
        else
            $config:data-root ! collection(. || "/" || $root)/*
    let $sorted := app:sort($filtered, $sort)
    return (
        session:set-attribute("teipublisher.works", $sorted),
        session:set-attribute("teipublisher.browse", $browse),
        session:set-attribute("teipublisher.filter", $filter),
        session:set-attribute("teipublisher.odd", $odd),
        map {
            "all" : $sorted,
            "mode": "browse"
        }
    )
};

declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:browse($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $filter as xs:string?) {
    let $total := count($model?all)
    let $start :=
        if ($start > $total) then
            ($total idiv $per-page) * $per-page + 1
        else
            $start
    return (
        response:set-header("pb-start", xs:string($start)),
        response:set-header("pb-total", xs:string($total)),

        if (empty($model?all) and (empty($filter) or $filter = "")) then
            templates:process($node/*[@class="empty"], $model)
        else
            subsequence($model?all, $start, $per-page) !
                templates:process($node/*[not(@class="empty")], map:new(
                    ($model, map {
                        "work": .,
                        "config": tpu:parse-pi(root(.), ()),
                        "ident": config:get-identifier(.),
                        "path": document-uri(root(.))
                    }))
                )
    )
};

declare function app:add-identifier($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute data-doc {
            config:get-identifier($model?work)
        },
        templates:process($node/node(), $model)
    }
};


declare
    %templates:wrap
function app:short-header($node as node(), $model as map(*)) {
    let $work := root($model("work"))/*
    let $relPath := config:get-identifier($work)
    let $config := tpu:parse-pi(root($work), (), ())
    let $header :=
        $pm-config:web-transform(nav:get-header($model?config, $work), map {
            "header": "short",
            "doc": $relPath
        }, $config?odd)
    return
        if ($header) then
            $header
        else
            <a href="{$relPath}">{util:document-name($work)}</a>
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
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/string()
    let $main-title := if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/string()
    return
        $main-title
};

declare function app:download-link($node as node(), $model as map(*),
    $doc as xs:string?, $mode as xs:string?) {
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
    return
        element { node-name($node) } {
            $node/@*,
            attribute url { $file },
            attribute odd { ($model?config?odd, $config:odd)[1] },
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
            case element(form) return
                let $action :=
                    replace(
                        $node/@action,
                        "\$app",
                        (request:get-context-path() || substring-after($config:app-root, "/db"))
                    )
                return
                    element { node-name($node) } {
                        attribute action {$action}, $node/@* except $node/@action, app:fix-links($node/node())
                    }
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
                            attribute href { app:parse-href($href) },
                            $node/@* except $node/@href,
                            app:fix-links($node/node())
                        }
            case element() return
                element { node-name($node) } {
                    $node/@*, app:fix-links($node/node())
                }
            default return
                $node
};

declare %private function app:parse-href($href as xs:string) {
    if (matches($href, "\$\{[^\}]+\}")) then
        string-join(
            let $parsed := analyze-string($href, "\$\{([^\}]+?)(?::([^\}]+))?\}")
            for $token in $parsed/node()
            return
                typeswitch($token)
                    case element(fn:non-match) return $token/string()
                    case element(fn:match) return
                        let $paramName := $token/fn:group[1]
                        let $default := $token/fn:group[2]
                        return
                            request:get-parameter($paramName, $default)
                    default return $token
        )
    else
        $href
};



declare function app:dispatch-action($node as node(), $model as map(*), $action as xs:string?) {
    switch ($action)
        case "delete" return
            let $docs := request:get-parameter("docs[]", ())
            return
                <div id="action-alert" class="alert alert-success">
                    <p>Removed {count($docs)} documents.</p>
                    {
                        for $path in $docs
                        let $doc := pages:get-document(xmldb:decode($path))
                        return
                            if ($doc) then
                                xmldb:remove(util:collection-name($doc), util:document-name($doc))
                            else
                                <p>Failed to remove document {$path}</p>
                    }
                </div>
        case "delete-odd" return
            let $docs := request:get-parameter("docs[]", ())
            return
                <div id="action-alert" class="alert alert-success">
                    <p>Removed {count($docs)} documents.</p>
                    {
                        for $path in $docs
                        let $doc := doc($config:odd-root || "/" || $path)
                        return
                            xmldb:remove(util:collection-name($doc), util:document-name($doc))
                    }
                </div>
        default return
            ()
};
