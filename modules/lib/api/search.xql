xquery version "3.1";

module namespace sapi="http://teipublisher.com/api/search";

import module namespace query="http://www.tei-c.org/tei-simple/query" at "../../query.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../../navigation.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace facets="http://teipublisher.com/facets" at "../../facets.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function sapi:autocomplete($request as map(*)) {
    let $q := request:get-parameter("query", ())
    let $type := request:get-parameter("field", "text")
    let $doc := request:get-parameter("doc", ())
    let $items :=
        if ($q) then
            query:autocomplete($doc, $type, $q)
        else
            ()
    return
        array {
            for $item in $items
            group by $item
            return
                map {
                    "text": $item,
                    "value": $item
                }
        }
};

declare function sapi:search($request as map(*)) {
    (:If there is no query string, fill up the map with existing values:)
    if (empty($request?parameters?query))
    then
        sapi:show-hits($request, session:get-attribute($config:session-prefix || ".hits"), session:get-attribute($config:session-prefix || ".docs"))
    else
        (:Otherwise, perform the query.:)
        (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
        (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
        let $hitsAll :=
                (:If the $query-scope is narrow, query the elements immediately below the lowest div in tei:text and the four major element below tei:teiHeader.:)
                for $hit in query:query-default($request?parameters?field, $request?parameters?query, $request?parameters?doc, ())
                order by ft:score($hit) descending
                return $hit
        let $hitCount := count($hitsAll)
        let $hits := if ($hitCount > 1000) then subsequence($hitsAll, 1, 1000) else $hitsAll
        (:Store the result in the session.:)
        let $store := (
            session:set-attribute($config:session-prefix || ".hits", $hitsAll),
            session:set-attribute($config:session-prefix || ".hitCount", $hitCount),
            session:set-attribute($config:session-prefix || ".search", $request?parameters?query),
            session:set-attribute($config:session-prefix || ".field", $request?parameters?field),
            session:set-attribute($config:session-prefix || ".docs", $request?parameters?doc)
        )
        return
            sapi:show-hits($request, $hits, $request?parameters?doc)
};

declare %private function sapi:show-hits($request as map(*), $hits as item()*, $docs as xs:string*) {
    response:set-header("pb-total", xs:string(count($hits))),
    response:set-header("pb-start", xs:string($request?parameters?start)),
    for $hit at $p in subsequence($hits, $request?parameters?start, $request?parameters?per-page)
    let $config := tpu:parse-pi(root($hit), $request?parameters?view)
    let $parent := query:get-parent-section($config, $hit)
    let $parent-id := config:get-identifier($parent)
    let $parent-id := if (exists($docs)) then replace($parent-id, "^.*?([^/]*)$", "$1") else $parent-id
    let $div := query:get-current($config, $parent)
    let $expanded := util:expand($hit, "add-exist-id=all")
    let $docId := config:get-identifier($div)
    return
        <paper-card>
            <header>
                <div class="count">{$request?parameters?start + $p - 1}</div>
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
                        (: Check if the document has sections, otherwise don't pass root :)
                        if (nav:get-section-for-node($config, $div)) then util:node-id($div) else ()
                let $config := <config width="60" table="no" link="{$docId}?{if ($docLink) then 'root=' || $docLink || '&amp;' else ()}action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
                return
                    kwic:get-summary($expanded, $match, $config)
            }
            </div>
        </paper-card>
};

declare function sapi:facets($request as map(*)) {
    
    let $hits := session:get-attribute($config:session-prefix || ".hits")
    where count($hits) > 0
    return
        <div>
        {
            for $config in $config:facets?*
            return
                facets:display($config, $hits)
        }
        </div>
};

declare function sapi:list-facets($request as map(*)) {
    let $type := $request?parameters?type
    let $lang := tokenize($request?parameters?language, '-')[1]
    let $facetConfig := filter($config:facets?*, function($facetCfg) {
        $facetCfg?dimension = $type
    })
    let $hits := session:get-attribute($config:session-prefix || ".hits")
    let $facets := ft:facets($hits, $type, ())
    
    let $matches := 
        for $key in if (exists($request?parameters?value)) then $request?parameters?value else map:keys($facets)
        let $label := facets:translate($facetConfig, $lang, $key)
        return 
            map {
                "text": $label,
                "freq": $facets($key),
                "value": $key
            } 
           
    let $filtered := filter($matches, function($item) {
        matches($item?text, '(?:^|\W)' || $request?parameters?query, 'i')
    })
    return
        array { $filtered }
};
