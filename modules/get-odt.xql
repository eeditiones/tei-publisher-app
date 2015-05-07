xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace odt="http://exist-db.org/xquery/odt" at "odt.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2odt($id as xs:string, $work as element(), $odd as xs:string) {
    let $root := $work/ancestor-or-self::tei:TEI
    let $fileDesc := $root/tei:teiHeader/tei:fileDesc
    let $config := map {
        "metadata": map {
            "title": $fileDesc/tei:titleStmt/tei:title/string(),
            "creator": $fileDesc/tei:titleStmt/tei:author/string(),
            "urn": util:uuid(),
            "language": "en"
        },
        "odd": $config:odd-root || "/" || $odd,
        "output-root": $config:output-root,
        "fonts": [ 
            "/db/apps/tei-simple/resources/fonts/Junicode.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Bold.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-BoldItalic.ttf",
            "/db/apps/tei-simple/resources/fonts/Junicode-Italic.ttf"
        ]
    }
    let $text := $root/tei:text/tei:body
    return
        odt:generate($config, $root, $id)
};

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", ())
let $id := substring-before($doc, ".xml")
let $work := doc($config:data-root || "/" || $doc)/tei:TEI
let $entries := local:work2odt($id, $work, $odd)
return
    (
        response:set-header("Content-Disposition", concat("attachment; filename=", concat($id, '.odt'))),
        response:stream-binary(
            compression:zip( $entries, true() ),
            'application/vnd.oasis.opendocument.text',
            concat($id, '.odt')
        )
    )