xquery version "3.0";

module namespace app="$$namespace$$";

import module namespace templates="http://exist-db.org/xquery/templates" $$templates$$;
import module namespace config="$$config-namespace$$" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace pages="$$pages-namespace$$" at "pages.xql";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : List documents in data collection
 :)
declare 
    %templates:wrap
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $browse as xs:string?) {
    let $cached := session:get-attribute("simple.works")
    let $filtered :=
        if ($filter) then
            let $ordered :=
                for $item in
                    ft:search($config:data-root, $browse || ":" || $filter, ("author", "title"))/search
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
            collection($config:data-root)/tei:TEI
    return (
        session:set-attribute("simple.works", $filtered),
        session:set-attribute("browse", $browse),
        session:set-attribute("filter", $filter),
        map {
            "all" : $filtered
        }
    )
};

declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:browse($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int) {
    subsequence($model?all, $start, $per-page) !
        element { node-name($node) } {
            $node/@*,
            templates:process($node/node(), map:new(($model, map { "work": . })))
        }
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
    %templates:default("key", "hits")
function app:hit-count($node as node()*, $model as map(*), $key as xs:string) {
    count($model($key))
};

declare 
    %templates:wrap
function app:checkbox($node as node(), $model as map(*), $target-texts as xs:string*) {
    let $id := $model("work")/@xml:id/string()
    return (
        attribute { "value" } {
            $id
        },
        if ($id = $target-texts) then
            attribute checked { "checked" }
        else
            ()
    )
};

(:~
 : 
 :)
declare function app:work-title($node as node(), $model as map(*), $type as xs:string?) {
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $id := util:document-name($work)
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$id}{$suffix}">{ app:work-title($work) }</a>
};

declare %private function app:work-title($work as element(tei:TEI)?) {
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()
    let $main-title := if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
    return
        $main-title
};

declare function app:work-author($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $work-authors := $work//tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt/tei:author
    return 
        string-join($work-authors, "; ")
};

declare 
    %templates:wrap
function app:work-edition($node as node(), $model as map(*)) {
    $model("work")/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:date/text()
};

declare function app:download-link($node as node(), $model as map(*), $type as xs:string, $doc as xs:string?,
    $source as xs:boolean?) {
    let $file := 
        if ($model?work) then 
            replace(util:document-name($model("work")), "^(.*?)\.[^\.]*$", "$1")
        else 
            replace($doc, "^(.*)\..*$", "$1")
    let $uuid := util:uuid()
    return
        element { node-name($node) } {
            $node/@*,
            attribute data-token { $uuid },
            attribute href { $node/@href || $file || "." || $type || "?token=" || $uuid || "&amp;cache=no" 
                || (if ($source) then "&amp;source=yes" else ())
            },
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

(: Search :)

(:~
: Execute the query. The search results are not output immediately. Instead they
: are passed to nested templates through the $model parameter.
:
: @author Wolfgang M. Meier
: @author Jens Østergaard Petersen
: @param $node 
: @param $model
: @param $query The query string. This string is transformed into a <query> element containing one or two <bool> elements in a Lucene query and it is transformed into a sequence of one or two query strings in an ngram query. The first <bool> and the first string contain the query as input and the second the query as transliterated into Devanagari or IAST as determined by $query-scripts. One <bool> and one query string may be empty.
: @param $index The index against which the query is to be performed, as the string "ngram" or "lucene".
: @param $lucene-query-mode If a Lucene query is performed, which of the options "any", "all", "phrase", "near-ordered", "near-unordered", "fuzzy", or "regex" have been selected (note that wildcard is not implemented, due to its syntactic overlap with regex).
: @param $tei-target A sequence of one or more targets within a TEI document, the tei:teiHeader or tei:text.
: @param $work-authors A sequence of the string "all" or of the xml:ids of the documents associated with the selected authors.
: @param $query-scripts A sequence of the string "all" or of the values "sa-Latn" or "sa-Deva", indicating whether or not the user wishes to transliterate the query string.
: @param $target-texts A sequence of the string "all" or of the xml:ids of the documents selected.

: @return The function returns a map containing the $hits, the $query, and the $query-scope. The search results are output through the nested templates, app:hit-count, app:paginate, and app:show-hits.
:)
declare 
    %templates:default("lucene-query-mode", "any")
    %templates:default("tei-target", "tei-text")
    %templates:default("query-scope", "narrow")
    %templates:default("work-authors", "all")
    %templates:default("query-scripts", "all")
    %templates:default("target-texts", "all")
function app:query($node as node()*, $model as map(*), $query as xs:string?, $lucene-query-mode as xs:string, $tei-target as xs:string+, $query-scope as xs:string, $work-authors as xs:string+, $query-scripts as xs:string, $target-texts as xs:string+) as map(*) {
        (:If there is no query string, fill up the map with existing values:)
        if (empty($query))
        then
            map {
                "hits" := session:get-attribute("apps.simple"),
                "hitCount" := session:get-attribute("apps.simple.hitCount"),
                "query" := session:get-attribute("apps.simple.query"),
                "scope" := $query-scope (:NB: what about the other arguments?:)
            }
        else
            (:Otherwise, perform the query.:)
            (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
            (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
            let $hits :=
                    (:If the $query-scope is narrow, query the elements immediately below the lowest div in tei:text and the four major element below tei:teiHeader.:)
                    for $hit in 
                        (:If both tei-text and tei-header is queried.:)
                        if (count($tei-target) eq 2)
                        then
                            collection($config:data-root)//tei:div[ft:query(., $query)] |
                            collection($config:data-root)//tei:head[ft:query(., $query)]
                        else
                            if ($tei-target = 'tei-text')
                            then
                                collection($config:data-root)//tei:div[ft:query(., $query)]
                            else 
                                if ($tei-target = 'tei-head')
                                then 
                                    collection($config:data-root)//tei:head[ft:query(., $query)]
                                else ()    
                    order by ft:score($hit) descending
                    return $hit
            let $hitCount := count($hits)
            let $hits := if ($hitCount > 1000) then subsequence($hits, 1, 1000) else $hits
            (:Store the result in the session.:)
            let $store := (
                session:set-attribute("apps.simple", $hits),
                session:set-attribute("apps.simple.hitCount", $hitCount),
                session:set-attribute("apps.simple.query", $query),
                session:set-attribute("apps.simple.scope", $query-scope)
                )
            return
                (: The hits are not returned directly, but processed by the nested templates :)
                map {
                    "hits" := $hits,
                    "hitCount" := $hitCount,
                    "query" := $query
                }
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare 
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer) {
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $parent := $hit/ancestor-or-self::tei:div[1]
    let $parent := if ($parent) then $parent else $hit/ancestor-or-self::tei:teiHeader  
    let $div := app:get-current($parent)
    let $parent-id := util:document-name($parent) || "_" || util:node-id($parent)
    let $div-id := util:document-name($div) || "_" || util:node-id($div)
    (:if the nearest div does not have an xml:id, find the nearest element with an xml:id and use it:)
    (:is this necessary - can't we just use the nearest ancestor?:) 
(:    let $div-id := :)
(:        if ($div-id) :)
(:        then $div-id :)
(:        else ($hit/ancestor-or-self::*[@xml:id]/@xml:id)[1]/string():)
    (:if it is not a div, it will not have a head:)
    let $div-head := $parent/tei:head/text()
    (:TODO: what if the hit is in the header?:)
    let $work := $hit/ancestor::tei:TEI
    let $work-title := app:work-title($work)
    (:the work always has xml:id.:)
    let $work-id := $work/@xml:id/string()
    let $work-id := if ($work-id) then $work-id else util:document-name($work) || "_1"
    (:pad hit with surrounding siblings:)
    let $hit-padded := $hit
(:    let $hit-padded := <hit>{($hit/preceding-sibling::*[1], $hit, $hit/following-sibling::*[1])}</hit>:)
        
    let $loc := 
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <a href="{$work-id}">{$work-title}</a>{if ($div-head) then ' / ' else ''}<a href="{$parent-id}.html?action=search">{$div-head}</a>
            </td>
        </tr>
    let $matchId := util:node-id($hit)
    let $config := <config width="60" table="yes" link="{$div-id}.xml?action=search#{$matchId}"/>
    let $expanded := util:expand($hit)
    return (
        $loc,
        for $match in subsequence($expanded//exist:match, 1, 5)
        let $kwic := kwic:get-summary($expanded, $match, $config)
        return $kwic
    )
};

declare %private function app:get-current($div as element()?) {
    if (empty($div)) then
        ()
    else
        if ($div instance of element(tei:teiHeader)) then
        $div
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