xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2epub($id as xs:string, $work as element(), $odd as xs:string) {
    let $root := $work/ancestor-or-self::tei:TEI
    let $fileDesc := $root/tei:teiHeader/tei:fileDesc
    let $title := $fileDesc/tei:titleStmt/tei:title/string()
    let $creator := $fileDesc/tei:titleStmt/tei:author/string()
    let $cssDefault := util:binary-to-string(util:binary-doc($config:odd-root || "/teisimple.css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
    let $text := $root/tei:text/tei:body
    let $urn := util:uuid()
    return
        epub:generate-epub($title, $creator, $root, $config:odd-root || "/" || $odd, $urn, $css, $id)
};

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", ())
let $id := substring-before($doc, ".xml")
let $work := doc($config:data-root || "/" || $doc)/tei:TEI
let $entries := local:work2epub($id, $work, $odd)
return
    (
        response:set-header("Content-Disposition", concat("attachment; filename=", concat($id, '.epub'))),
        response:stream-binary(
            compression:zip( $entries, true() ),
            'application/epub+zip',
            concat($id, '.epub')
        )
    )