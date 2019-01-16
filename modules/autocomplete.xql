xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace query="http://www.tei-c.org/tei-simple/query" at "query.xql";

declare option output:method "json";
declare option output:media-type "application/json";

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
