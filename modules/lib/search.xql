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
declare namespace templates="http://exist-db.org/xquery/templates";

import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

(:~
: Execute the query. The search results are not output immediately. Instead they
: are passed to nested templates through the $model parameter.
:
: @author Wolfgang M. Meier
: @author Jens Østergaard Petersen
: @param $node
: @param $model
: @param $query The query string. This string is transformed into a <query> element containing one or two <bool> elements in a Lucene query and it is transformed into a sequence of one or two query strings in an ngram query. The first <bool> and the first string contain the query as input and the second the query as transliterated into Devanagari or IAST as determined by $query-scripts. One <bool> and one query string may be empty.
: @param $tei-target A sequence of one or more targets within a TEI document, the tei:teiHeader or tei:text.
: @param $target-texts A sequence of the string "all" or of the xml:ids of the documents selected.

: @return The function returns a map containing the $hits and the $query. The search results are output through the nested templates, browse:hit-count, browse:paginate, and browse:show-hits.
:)
declare
    %templates:default("field", "text")
function search:query($node as node()*, $model as map(*), $query as xs:string?, $field as xs:string+, $doc as xs:string*) as map(*) {
        (:If there is no query string, fill up the map with existing values:)
        if (empty($query))
        then
            map {
                "hits" : session:get-attribute($config:session-prefix || ".hits"),
                "hitCount" : session:get-attribute($config:session-prefix || ".hitCount"),
                "query" : session:get-attribute($config:session-prefix || ".query"),
                "docs" : session:get-attribute($config:session-prefix || ".docs")
            }
        else
            (:Otherwise, perform the query.:)
            (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
            (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
            let $hitsAll :=
                    (:If the $query-scope is narrow, query the elements immediately below the lowest div in tei:text and the four major element below tei:teiHeader.:)
                    for $hit in query:query-default($field, $query, $doc, ())
                    order by ft:score($hit) descending
                    return $hit
            let $hitCount := count($hitsAll)
            let $hits := if ($hitCount > 1000) then subsequence($hitsAll, 1, 1000) else $hitsAll
            (:Store the result in the session.:)
            let $store := (
                session:set-attribute($config:session-prefix || ".hits", $hitsAll),
                session:set-attribute($config:session-prefix || ".hitCount", $hitCount),
                session:set-attribute($config:session-prefix || ".query", $query),
                session:set-attribute($config:session-prefix || ".field", $field),
                session:set-attribute($config:session-prefix || ".docs", $doc)
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
    response:set-header("pb-total", xs:string(count($model?hits))),
    response:set-header("pb-start", xs:string($start)),
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $config := tpu:parse-pi(root($hit), $view)
    let $parent := query:get-parent-section($config, $hit)
    let $parent-id := config:get-identifier($parent)
    let $parent-id := if ($model?docs) then replace($parent-id, "^.*?([^/]*)$", "$1") else $parent-id
    let $div := query:get-current($config, $parent)
    let $expanded := util:expand($hit, "add-exist-id=all")
    let $docId := config:get-identifier($div)
    return
        <paper-card>
            <header>
                <div class="count">{$start + $p - 1}</div>
                { query:get-breadcrumbs($config, $hit, $parent-id) }
            </header>
            <div class="matches">
            {
                for $match in subsequence($expanded//exist:match, 1, 5)
                let $matchId := $match/../@exist:id
                let $docLink :=
                    if ($config?view = "page") then
                        (: first check if there's a pb in the expanded section before the match :)
                        let $pbBefore := $match/preceding::tei:pb[1]
                        return
                            if ($pbBefore) then
                                $pbBefore/@exist:id
                            else
                                (: no: locate the element containing the match in the source document :)
                                let $contextNode := util:node-by-id($hit, $matchId)
                                (: and get the pb preceding it :)
                                let $page := $contextNode/preceding::tei:pb[1]
                                return
                                    if ($page) then
                                        util:node-id($page)
                                    else
                                        util:node-id($div)
                    else
                        util:node-id($div)
                let $config := <config width="60" table="no" link="{$docId}?root={$docLink}&amp;action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
                return
                    kwic:get-summary($expanded, $match, $config)
            }
            </div>
        </paper-card>
};
