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

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";


declare
    %templates:wrap
function app:sort($items as element()*, $sortBy as xs:string?) {
    let $items :=
        if (exists($config:data-exclude)) then
            $items except $config:data-exclude
        else
            $items
    return
        if ($sortBy) then
            nav:sort($sortBy, $items)
        else
            $items
};

declare function app:is-writeable($node as node(), $model as map(*)) {
    let $path := $config:data-root || "/" || $model?root
    let $writable := sm:has-access(xs:anyURI($path), "rw-")
    return
        element { node-name($node) } {
            $node/@* except $node/@class,
            attribute class {
                string-join(($node/@class, if ($writable) then "writable" else ()), " ")
            },
            attribute data-root {
                $model?root
            },
            templates:process($node/node(), $model)
        }
};

(:~
 : List documents in data collection
 :)
declare
    %templates:wrap
    %templates:default("sort", "title")
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $browse as xs:string?, $odd as xs:string?, $sort as xs:string) {
    let $params := app:params2map($model?root)
    let $cached := session:get-attribute($config:session-prefix || ".works")
    let $filtered :=
        if (app:use-cache($params, $cached)) then
            $cached
        else if (exists($filter) and $filter != '') then
            query:query-metadata($browse, $filter, $sort)
        else
            let $options := query:options($sort)
            return
                nav:get-root($model?root, $options)
    let $sorted := app:sort($filtered, $sort)
    return (
        session:set-attribute($config:session-prefix || ".timestamp", current-dateTime()),
        session:set-attribute($config:session-prefix || '.hits', $filtered),
        session:set-attribute($config:session-prefix || '.params', $params),
        session:set-attribute($config:session-prefix || ".works", $sorted),
        map {
            "all" : $sorted,
            "mode": "browse"
        }
    )
};

declare %private function app:params2map($root as xs:string?) {
    map:merge((
        for $param in request:get-parameter-names()[not(. = ("start", "per-page"))]
        return
            map:entry($param, request:get-parameter($param, ())),
        map { "root": $root }
    ))
};

declare 
    %templates:wrap
function app:clear-facets($node as node(), $model as map(*)) {
    session:set-attribute($config:session-prefix || ".hits", ()),
    map {}
};

declare function app:use-cache($params as map(*), $cached) {
    let $cachedParams := session:get-attribute($config:session-prefix || ".params")
    let $timestamp := session:get-attribute($config:session-prefix || ".timestamp")
    return
        if (exists($cached) and exists($cachedParams) and deep-equal($params, $cachedParams) and exists($timestamp)) then
            empty(xmldb:find-last-modified-since(collection($config:data-root), $timestamp))
        else
            false()
};

declare function app:parent-collection($node as node(), $model as map(*)) {
    if (not($model?root) or $model?root = "") then
        ()
    else
        let $parts := tokenize($model?root, "/")
        return
            element { node-name($node) } {
                $node/@*,
                attribute data-collection { string-join(subsequence($parts, 1, count($parts) - 1)) },
                templates:process($node/node(), $model)
            }
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
                templates:process($node/*[not(@class="empty")], map:merge(
                    ($model, map {
                        "work": .,
                        "config": tpu:parse-pi(root(.), ()),
                        "ident": config:get-identifier(.),
                        "path": document-uri(root(.))
                    }))
                )
    )
};

declare
    %templates:wrap
function app:short-header($node as node(), $model as map(*)) {
        let $work := root($model("work"))/*
        let $relPath := config:get-identifier($work)
        return
            try {
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
            } catch * {
                <a href="{$relPath}">{util:document-name($work)}</a>,
                <p class="error">Failed to output document metadata: {$err:description}</p>
            }
};

declare function app:download-link($node as node(), $model as map(*), $mode as xs:string?) {
    let $file := config:get-identifier($model?work)
    return
        element { node-name($node) } {
            $node/@*,
            attribute url { $model?app || "api/document/" || escape-uri($file, true()) },
            attribute odd { ($model?config?odd, $config:default-odd)[1] },
            $node/node()
        }
};

declare function app:dispatch-action($node as node(), $model as map(*), $action as xs:string?) {
    switch ($action)
        case "delete" return
            let $docs := request:get-parameter("docs[]", ())
            let $result :=
                for $path in $docs
                let $doc := config:get-document(xmldb:decode($path))
                return
                    if ($doc) then
                        try {
                            xmldb:remove(util:collection-name($doc), util:document-name($doc))
                        } catch * {
                            <p class="error">Failed to remove document {$path} (insufficient permissions?)</p>
                        }
                    else
                        <p>Document not found: {$path}</p>
            return
                <div id="action-alert" class="alert alert-success">
                    <p>Removed {count($docs) - count($result)} documents.</p>
                    { $result }
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
