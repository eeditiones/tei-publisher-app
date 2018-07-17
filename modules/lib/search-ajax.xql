(:
 :
 :  Copyright (C) 2018 Wolfgang Meier
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

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:show-hits($hits as node()*, $start as xs:integer, $per-page as xs:integer, $view as xs:string?,
    $doc as xs:string?) {
    for $hit at $p in subsequence($hits, $start, $per-page)
    let $config := tpu:parse-pi(root($hit), $view)
    let $parent := query:get-parent-section($config, $hit)
    let $parent-id := config:get-identifier($parent)
    let $parent-id := if ($doc) then replace($parent-id, "^.*?([^/]*)$", "$1") else $parent-id
    let $div := query:get-current($config, $parent)
    let $expanded := util:expand($hit, "add-exist-id=all")
    let $docId := config:get-identifier($div)
    return map {
        "num": $start + $p - 1,
        "breadcrumbs": query:get-breadcrumbs($config, $hit, $parent-id),
        "matches": array {
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
            let $config := <config width="60" table="yes" link="{$docId}?root={$docLink}&amp;action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
            let $summary := kwic:get-summary($expanded, $match, $config)
            let $hi := $summary//*[@class = 'hi']
            return
                map {
                    "before": $summary//td[@class = 'previous']/string(),
                    "after": $summary//td[@class = 'following']/string(),
                    "hi": map {
                        "link": $hi/a/@href,
                        "content": $hi//string()
                    }
                }
        }
    }
};


let $query := request:get-parameter("query", ())
let $tei-target := request:get-parameter("tei-target", "tei-text")
let $doc := request:get-parameter("doc", ())
let $start := request:get-parameter("start", 1)
let $per-page := request:get-parameter("count", 10)
return
    (:If there is no query string, fill up the map with existing values:)
    if (empty($query))
    then
        map {
            "hits" : session:get-attribute("apps.simple"),
            "hitCount" : session:get-attribute("apps.simple.hitCount"),
            "query" : session:get-attribute("apps.simple.query"),
            "docs" : session:get-attribute("apps.simple.docs")
        }
    else
        (:Otherwise, perform the query.:)
        (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
        (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
        let $hits :=
                (:If the $query-scope is narrow, query the elements immediately below the lowest div in tei:text and the four major element below tei:teiHeader.:)
                for $hit in query:query-default($tei-target, $query, $doc)
                order by ft:score($hit) descending
                return $hit
        let $hitCount := count($hits)
        let $hits := if ($hitCount > 1000) then subsequence($hits, 1, 1000) else $hits
        (:Store the result in the session.:)
        let $store := (
            session:set-attribute("apps.simple", $hits),
            session:set-attribute("apps.simple.hitCount", $hitCount),
            session:set-attribute("apps.simple.query", $query),
            session:set-attribute("apps.simple.docs", $doc)
        )
        return
            (: The hits are not returned directly, but processed by the nested templates :)
            map {
                "hits" : local:show-hits($hits, $start, $per-page, (), ()),
                "hitCount" : $hitCount,
                "query" : $query,
                "docs": $doc
            }
