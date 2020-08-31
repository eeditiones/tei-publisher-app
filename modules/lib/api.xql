xquery version "3.1";

declare namespace api="https://tei-publisher.com/xquery/api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router" at "/db/apps/oas-router/content/router.xql";
import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace oapi="http://teipublisher.com/api/odd" at "api/odd.xql";
import module namespace dapi="http://teipublisher.com/api/documents" at "api/document.xql";
import module namespace capi="http://teipublisher.com/api/collection" at "api/collection.xql";
import module namespace sapi="http://teipublisher.com/api/search" at "api/search.xql";

declare function api:list-templates($request as map(*)) {
    array {
        for $html in collection($config:app-root || "/templates/pages")/*
        let $description := $html//meta[@name="description"]/@content/string()
        return
            map {
                "name": util:document-name($html),
                "title": $description
            }
    }
};

let $lookup := function($name as xs:string) {
    function-lookup(xs:QName($name), 1)
}
let $resp := router:route("modules/lib/api.json", $lookup)
return
    $resp