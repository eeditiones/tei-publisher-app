xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2epub($id as xs:string, $work as element(), $odd as xs:string) {
    let $root := root($work)
    let $fileDesc := $root/tei:teiHeader/tei:fileDesc
    let $config := map {
        "metadata": map {
            "title": $fileDesc/tei:titleStmt/tei:title/string(),
            "creator": $fileDesc/tei:titleStmt/tei:author/string(),
            "urn": util:uuid(),
            "language": "en"
        },
        "odd": $odd,
        "odd-root": $config:odd-root,
        "compiled-odd-root": $config:compiled-odd-root,
        "output-root": $config:output-root,
        "fonts": [ 
            "/db/apps/tei-simple/resources/fonts/Junicode.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Bold.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-BoldItalic.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Italic.ttf"
        ]
    }
    let $cssDefault := util:binary-to-string(util:binary-doc($config:output-root || "/teisimple.css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
    return
        epub:generate-epub($config, $root, $css, $id)
};

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", ())
let $id := replace($doc, "^.*?([^/]+)\..*$", "$1")
let $work := doc($config:app-root || "/" || $doc)/*
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