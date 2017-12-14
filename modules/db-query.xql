(:
 :
 :  Copyright (C) 2017 Wolfgang Meier
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

module namespace dbs="http://www.tei-c.org/tei-simple/query/docbook";

declare namespace db="http://docbook.org/ns/docbook";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation/docbook" at "navigation-dbk.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $dbs:QUERY_OPTIONS :=
    <options>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>;

declare function dbs:query-default($fields as xs:string, $query as xs:string, $target-texts as xs:string*) {
    if(string($query)) then
        for $field in $fields
        return
            switch ($field)
                case "tei-head" return
                    if ($target-texts) then
                        for $text in $target-texts
                        return
                            $config:data-root ! doc(. || "/" || $text)//db:title[ft:query(., $query, $dbs:QUERY_OPTIONS)]
                    else
                        collection($config:data-root)//db:title[ft:query(., $query, $dbs:QUERY_OPTIONS)]
                default return
                    switch ($config:search-default)
                        case "tei:div" return
                            if ($target-texts) then
                                for $text in $target-texts
                                return
                                    $config:data-root ! doc(. || "/" || $text)//db:section[ft:query(., $query, $dbs:QUERY_OPTIONS)][not(db:section)]
                            else
                                collection($config:data-root)//db:section[ft:query(., $query, $dbs:QUERY_OPTIONS)][not(db:section)]
                        case "tei:body" return
                            if ($target-texts) then
                                for $text in $target-texts
                                return
                                    $config:data-root !
                                        doc(. || "/" || $text)//db:article[ft:query(., $query, $dbs:QUERY_OPTIONS)]
                            else
                                collection($config:data-root)//db:article[ft:query(., $query, $dbs:QUERY_OPTIONS)]
                        default return
                            if ($target-texts) then
                                util:eval("for $text in $target-texts return $config:data-root ! doc(. || '/' || $text)//db:article[ft:query(., $query, $dbs:QUERY_OPTIONS)]")
                            else
                                util:eval("collection($config:data-root)//" || $config:search-default || "[ft:query(., $query, $dbs:QUERY_OPTIONS)]")
    else ()
};

declare function dbs:get-parent-section($node as node()) {
    ($node/self::db:article, $node/ancestor-or-self::db:section[1], $node)[1]
};

declare function dbs:get-breadcrumbs($config as map(*), $hit as element(), $parent-id as xs:string) {
    let $work := root($hit)/*
    let $work-title := nav:get-document-title($config, $work)
    return
        <ol class="headings breadcrumb">
            <li><a href="{$parent-id}">{$work-title}</a></li>
            {
                for $parentDiv in $hit/ancestor-or-self::db:section[db:title]
                let $id := util:node-id($parentDiv)
                return
                    <li>
                        <a href="{$parent-id}?action=search&amp;root={$id}&amp;view={$config?view}&amp;odd={$config?odd}">{$parentDiv/db:title/string()}</a>
                    </li>
            }
        </ol>
};

(:~
 : Expand the given element and highlight query matches by re-running the query
 : on it.
 :)
declare function dbs:expand($data as element()) {
    let $query := session:get-attribute("apps.simple.query")
    let $div := $data
    let $expanded :=
        util:expand(
            (
                dbs:query-default-view($div, $query),
                $div[.//db:title[ft:query(., $query, $dbs:QUERY_OPTIONS)]]
            ), "add-exist-id=all"
        )
    return
        $expanded
};


declare %private function dbs:query-default-view($context as element()*, $query as xs:string) {
    switch ($config:search-default)
        case "tei:div" return
            $context[./descendant-or-self::db:section[ft:query(., $query, $dbs:QUERY_OPTIONS)]]
        case "tei:body" return
            $context[./descendant-or-self::db:article[ft:query(., $query, $dbs:QUERY_OPTIONS)]]
        default return
            util:eval("$context[./descendant-or-self::" || $config:search-default || "[ft:query(., $query, $dbs:QUERY_OPTIONS)]]")
};

declare function dbs:get-current($config as map(*), $div as element()?) {
    $div
};
