xquery version "3.1";

module namespace sapi="http://teipublisher.com/api/search";

import module namespace query="http://www.tei-c.org/tei-simple/query" at "../../query.xql";

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
            return
                map {
                    "text": $item,
                    "value": $item
                }
        }
};