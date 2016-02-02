xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2epub($id as xs:string, $work as element()) {
    let $root := $work/ancestor-or-self::tei:TEI
    let $fileDesc := $root/tei:teiHeader/tei:fileDesc
    let $config := map {
        "metadata": map {
            "title": $fileDesc/tei:titleStmt/tei:title/string(),
            "creator": $fileDesc/tei:titleStmt/tei:author/string(),
            "urn": util:uuid(),
            "language": "en"
        },
        "odd": $config:odd,
        "output-root": $config:odd-root,
        "fonts": [ 
            "/db/apps/tei-simple/resources/fonts/Junicode.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Bold.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-BoldItalic.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Italic.ttf"
        ]
    }
    let $oddName := replace($config:odd, "^([^/\.]+).*$", "$1")
    let $cssDefault := util:binary-to-string(util:binary-doc($config:output-root || "/" || $oddName || ".css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
    let $text := $root/tei:text/tei:body
    return
        epub:generate-epub($config, $root, $css, $id)
};

let $id := request:get-parameter("id", ())
let $token := request:get-parameter("token", ())
let $work := doc($config:data-root || "/" || $id || ".xml")/tei:TEI
let $entries := local:work2epub($id, $work)
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