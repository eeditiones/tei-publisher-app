xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2epub($id as xs:string, $work as document-node(), $lang as xs:string?) {
    let $config := $config:epub-config($work, $lang)
    let $oddName := replace($config:odd, "^([^/\.]+).*$", "$1")
    let $cssDefault := util:binary-to-string(util:binary-doc($config:output-root || "/" || $oddName || ".css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
    return
        epub:generate-epub($config, $work/*, $css, $id)
};

let $id := replace(request:get-parameter("id", ""), "^(.*)\..*", "$1")
let $token := request:get-parameter("token", ())
let $lang := request:get-parameter("lang", ())
let $work := pages:get-document($id)
let $entries := local:work2epub($id, $work, $lang)
return
    (
        response:set-cookie("simple.token", $token),
        response:set-header("Content-Disposition", concat("attachment; filename=", concat($id, '.epub'))),
        response:stream-binary(
            compression:zip( $entries, true() ),
            'application/epub+zip',
            concat($id, '.epub')
        )
    )