xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace dapi="http://teipublisher.com/api/documents" at "lib/api/document.xql";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace roaster="http://e-editiones.org/roaster";

declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

(:~
 : Encylopedia example: "Damen Conversations Lexikon"
 :
 : Outputs a list of lemmata. The returned JSON structure will be in the format
 : required by `<pb-split-list>`.
 :
 : @see templates/pages/tei-lex.html
 :)
declare function api:lemmata($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category
    let $limit := $request?parameters?limit
    let $entries :=
        if ($search and $search != '')
        then
            doc($config:data-root || "/test/DamenConvLex-1834.xml")//tei:entry[ft:query(., 'lemma:(' || $search || '*)', map {
                "leading-wildcard": "yes",
                "filter-rewrite": "yes",
                "fields": "lemma"
            })]
        else
            doc($config:data-root || "/test/DamenConvLex-1834.xml")//tei:entry[ft:query(., 'lemma:*', map {
                "leading-wildcard": "yes",
                "filter-rewrite": "yes",
                "fields": "lemma"
            })]
    let $byLetter :=
        map:merge(
            for $entry in $entries
            let $term := upper-case(ft:field($entry, "lemma"))
            order by $term
            group by $letter := substring($term, 1, 1)
            return
                map:entry($letter, $entry)
        )
    let $letter :=
        if ((count($entries) < $limit)) then
            "[A-Z]"
        else if (empty($letterParam) or $letterParam = '') then
            head(sort(map:keys($byLetter)))
        else
            $letterParam
    let $itemsToShow :=
        if ($letter = '[A-Z]') then
            $entries
        else
            $byLetter($letter)
    return
        map {
            "letter": $letter,
            "categories":
                if ((count($entries) < $limit)) then
                    []
                else array {
                    for $index in 1 to string-length('AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ')
                    let $alpha := substring('AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ', $index, 1)
                    let $hits := count($byLetter($alpha))
                    where $hits > 0
                    return
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                    map {
                        "category": "[A-Z]",
                        "count": count($entries),
                        "label": <pb-i18n key="all">all</pb-i18n>
                    }
                },
            "items": api:output-lemma($itemsToShow, $letter, $search)
        }
};

declare %private function api:output-lemma($list, $category as xs:string, $search as xs:string?) {
    array {
        for $lemma in $list
        let $lemmaField := ft:field($lemma, "lemma")
        return
            <div class="term">
                <pb-link emit="detail" subscribe="detail" params='{{"search": "{$lemmaField}"}}'>
                    {$lemmaField}
                </pb-link>
            </div>
    }
};