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
 : Template functions to handle search.
 :)
module namespace search="http://www.tei-c.org/tei-simple/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "browse.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

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

: @return The function returns a map containing the $hits, the $query, and the $query-scope. The search results are output through the nested templates, browse:hit-count, browse:paginate, and browse:show-hits.
:)
declare
    %templates:default("lucene-query-mode", "any")
    %templates:default("tei-target", "tei-text")
    %templates:default("query-scope", "narrow")
    %templates:default("work-authors", "all")
    %templates:default("query-scripts", "all")
function search:query($node as node()*, $model as map(*), $query as xs:string?, $lucene-query-mode as xs:string, $tei-target as xs:string+, $query-scope as xs:string, $work-authors as xs:string+, $query-scripts as xs:string, $doc as xs:string*) as map(*) {
        (:If there is no query string, fill up the map with existing values:)
        if (empty($query))
        then
            map {
                "hits" : session:get-attribute("apps.simple"),
                "hitCount" : session:get-attribute("apps.simple.hitCount"),
                "query" : session:get-attribute("apps.simple.query"),
                "scope" : $query-scope,
                "docs" : session:get-attribute("apps.simple.docs")
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
                            search:query-default($query, $doc) |
                            search:query-headings($query, $doc)
                        else
                            if ($tei-target = 'tei-text')
                            then
                                search:query-default($query, $doc)
                            else
                                if ($tei-target = 'tei-head')
                                then
                                    search:query-headings($query, $doc)
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
                session:set-attribute("apps.simple.scope", $query-scope),
                session:set-attribute("apps.simple.docs", $doc)
            )
            return
                (: The hits are not returned directly, but processed by the nested templates :)
                map {
                    "hits" : $hits,
                    "hitCount" : $hitCount,
                    "query" : $query,
                    "docs": $doc
                }
};

declare function search:query-default($query as xs:string, $target-texts as xs:string*) {
    switch ($config:search-default)
        case "tei:div" return
            if ($target-texts) then
                for $text in $target-texts
                return
                    $config:data-root ! doc(. || "/" || $text)//tei:div[ft:query(., $query)][not(tei:div)]
            else
                collection($config:data-root)//tei:div[ft:query(., $query)][not(tei:div)]
        case "tei:body" return
            if ($target-texts) then
                for $text in $target-texts
                return
                    $config:data-root !
                        doc(. || "/" || $text)//tei:body[ft:query(., $query)]
            else
                collection($config:data-root)//tei:body[ft:query(., $query)]
        default return
            if ($target-texts) then
                util:eval("for $text in $target-texts return $config:data-root ! doc(. || '/' || $text)//tei:body[ft:query(., $query)]")
            else
                util:eval("collection($config:data-root)//" || $config:search-default || "[ft:query(., $query)]")
};

declare function search:query-headings($query as xs:string, $target-texts as xs:string*) {
    if ($target-texts) then
        for $text in $target-texts
        return
            $config:data-root ! doc(. || "/" || $text)//tei:head[ft:query(., $query)]
    else
        collection($config:data-root)//tei:head[ft:query(., $query)]
};


declare function search:query-default-view($context as element()*, $query as xs:string) {
    switch ($config:search-default)
        case "tei:div" return
            $context[./descendant-or-self::tei:div[ft:query(., $query)]]
        case "tei:body" return
            $context[./descendant-or-self::tei:body[ft:query(., $query)]]
        default return
            util:eval("$context[./descendant-or-self::" || $config:search-default || "[ft:query(., $query)]]")
};

declare function search:form-current-doc($node as node(), $model as map(*), $doc as xs:string?) {
    <input type="hidden" name="doc" value="{$doc}"/>
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function search:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?) {
    console:log("docs: " || count($model?docs)),
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $parent := ($hit/self::tei:body, $hit/ancestor-or-self::tei:div[1])[1]
    let $parent := ($parent, $hit/ancestor-or-self::tei:teiHeader, $hit)[1]
    let $parent-id := config:get-identifier($parent)
    let $parent-id :=
        if ($model?docs) then replace($parent-id, "^.*?([^/]*)$", "$1") else $parent-id
    let $work := $hit/ancestor::tei:TEI
    let $work-title := browse:work-title($work)
    let $config := tpu:parse-pi(root($work), $view)
    let $div := search:get-current($config, $parent)
    let $loc :=
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <ol class="headings breadcrumb">
                    <li><a href="{$parent-id}">{$work-title}</a></li>
                    {
                        for $parentDiv in $hit/ancestor-or-self::tei:div[tei:head]
                        let $id := util:node-id(
                            if ($config?view = "page") then $parentDiv/preceding::tei:pb[1] else $parentDiv
                        )
                        return
                            <li>
                                <a href="{$parent-id}?action=search&amp;root={$id}&amp;view={$config?view}&amp;odd={$config?odd}">{$parentDiv/tei:head//text()}</a>
                            </li>
                    }
                </ol>
            </td>
        </tr>
    let $expanded := util:expand($hit, "add-exist-id=all")
    let $docId := config:get-identifier($div)
    let $docId :=
        if ($model?docs) then
            replace($docId, "^.*?([^/]*)$", "$1")
        else
            $docId
    return (
        $loc,
        for $match in subsequence($expanded//exist:match, 1, 5)
        let $matchId := $match/../@exist:id
        let $docLink :=
            if ($config?view = "page") then
                let $contextNode := util:node-by-id($div, $matchId)
                let $page := $contextNode/preceding::tei:pb[1]
                return
                    util:node-id($page)
            else
                util:node-id($div)
        let $config := <config width="60" table="yes" link="{$docId}?root={$docLink}&amp;action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
        return
            kwic:get-summary($expanded, $match, $config)
    )
};

declare %private function search:get-current($config as map(*), $div as element()?) {
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
                nav:get-previous-div($config, $div/..)
            else
                $div
};
