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

module namespace jats="http://www.tei-c.org/tei-simple/query/jats";

declare namespace db="http://docbook.org/ns/docbook";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation/docbook" at "navigation-dbk.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "query.xql";

declare variable $jats:FIELD_PREFIX := "jats.";

declare function jats:query-default($fields as xs:string+, $query as xs:string, $target-texts as xs:string*,
    $sortBy as xs:string*) {
    if(string($query)) then
        for $field in $fields
        return
            switch ($field)
                case "head" return
                    if (exists($target-texts)) then
                        for $text in $target-texts
                        return
                            $config:data-root ! doc(. || "/" || $text)//db:title[ft:query(., $query, query:options($sortBy))]
                    else
                        collection($config:data-root)//db:title[ft:query(., $query, query:options($sortBy))]
                default return
                    if (exists($target-texts)) then
                        for $text in $target-texts
                        return
                            $config:data-root ! doc(. || "/" || $text)//body[ft:query(., $query, query:options($sortBy))] |
                            $config:data-root ! doc(. || "/" || $text)//sec[ft:query(., $query, query:options($sortBy))]
                    else
                        collection($config:data-root)//body[ft:query(., $query, query:options($sortBy))] |
                        collection($config:data-root)//sec[ft:query(., $query, query:options($sortBy))]
    else ()
};

declare function jats:autocomplete($doc as xs:string?, $fields as xs:string+, $q as xs:string) {
    for $field in $fields
    return
        switch ($field)
            case "text" return
                if ($doc) then (
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("sec"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index"),
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("sec"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index")
                ) else (
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("sec"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index"),
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("sec"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index")
                )
            case "head" return
                if ($doc) then
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("db:title"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index")
                else
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("db:title"), $q,
                        function($key, $count) {
                            $key
                        }, 30, "lucene-index")
            case "author" return
                collection($config:data-root)/ft:index-keys-for-field($jats:FIELD_PREFIX || "author", $q,
                    function($key, $count) {
                        $key
                    }, 30)
            case "file" return
                collection($config:data-root)/ft:index-keys-for-field($jats:FIELD_PREFIX || "file", $q,
                    function($key, $count) {
                        $key
                    }, 30)
            default return
                collection($config:data-root)/ft:index-keys-for-field($jats:FIELD_PREFIX || "title", $q,
                    function($key, $count) {
                        $key
                    }, 30)
};

declare function jats:query-metadata($path as xs:string?, $field as xs:string?, $query as xs:string?, $sort as xs:string) {
    let $queryExpr := 
        if ($field = "file" or empty($query) or $query = '') then 
            $jats:FIELD_PREFIX || "file:*" 
        else 
            $jats:FIELD_PREFIX || ($field, "text")[1] || ":" || $query
    let $options := query:options($sort, ($field, "text")[1])
    let $result :=
        $config:data-default ! (
            collection(. || "/" || $path)//body[ft:query(., $queryExpr, $options)]
        )
    return
        query:sort($result, $sort)
};

declare function jats:get-parent-section($node as node()) {
    ($node/self::body, $node/ancestor-or-self::sec[1], $node)[1]
};

declare function jats:get-breadcrumbs($config as map(*), $hit as node(), $parent-id as xs:string) {
    let $work := root($hit)/*
    let $work-title := nav:get-document-title($config, $work)
    return
        <div class="breadcrumbs">
            <a class="breadcrumb" href="{$parent-id}">{$work-title}</a>
            {
                for $parentDiv in $hit/ancestor-or-self::sec[title]
                let $id := util:node-id($parentDiv)
                return
                    <a class="breadcrumb" href="{$parent-id}?action=search&amp;root={$id}&amp;view={$config?view}&amp;odd={$config?odd}">
                    {$parentDiv/title/string()}
                    </a>
            }
        </div>
};

(:~
 : Expand the given element and highlight query matches by re-running the query
 : on it.
 :)
declare function jats:expand($data as node()) {
    let $query := session:get-attribute($config:session-prefix || ".query")
    let $field := session:get-attribute($config:session-prefix || ".field")
    let $div := $data
    let $result := jats:query-default-view($div, $query, $field)
    let $expanded :=
        if (exists($result)) then
            util:expand($result, "add-exist-id=all")
        else
            $div
    return
        $expanded
};


declare %private function jats:query-default-view($context as element()*, $query as xs:string, $fields as xs:string+) {
    for $field in $fields
    return
        switch ($field)
            case "head" return
                $context[./descendant-or-self::title[ft:query(., $query, $query:QUERY_OPTIONS)]]
            default return
                $context[./descendant-or-self::sec[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                $context[./descendant-or-self::body[ft:query(., $query, $query:QUERY_OPTIONS)]]
};

declare function jats:get-current($config as map(*), $div as node()?) {
    $div
};
