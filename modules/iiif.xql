module namespace iiif="https://stonesutras.org/api/iiif";

import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Base URI of the IIIF image API service to use for the images
 :)
declare variable $iiif:IMAGE_API_BASE := "https://apps.existsolutions.com/cantaloupe/iiif/2/";

declare %private function iiif:image-info($path as xs:string) {
    let $request := <http:request method="GET" href="{$iiif:IMAGE_API_BASE}/{$path}/info.json"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = 200) then
            let $data := util:binary-to-string(xs:base64Binary($response[2]))
            return
                parse-json($data)
        else
            ()
};

declare %private function iiif:structures($catalog as element(), $canvases as map(*)*) {
    array {
        for $canvas at $p in $canvases
        return
            map {
                "@id": "https://e-editiones.org/iiif/presentation/" || $catalog/@xml:id || "/range/" || $p,
                "@type": "sc:Range",
                "canvases": [
                    $canvas("@id")
                ]
            }
    }
};

declare %private function iiif:canvases($doc as node()) {
    for $pb in $doc//tei:body//tei:pb
    let $id := substring-after($pb/@facs, "FFimg:")
    let $info := iiif:image-info($id)
    where exists($info)
    return
        map {
            "@id": "https://e-editiones.org/canvas/page-" || $pb/@n || ".json",
            "@type": "sc:Canvas",
            "label": "Page " || $pb/@n,
            "width": $info?width,
            "height": $info?height,
            "images": [
                map {
                    "@type": "oa:Annotation",
                    "motivation": "sc:painting",
                    "resource": map {
                        "@id": $iiif:IMAGE_API_BASE || "/" || $id || "/full/full/0/default.jpg",
                        "@type": "dctypes:Image",
                        "format": "image/jpeg",
                        "width": $info?width,
                        "height": $info?height,
                        "service": map {
                            "@context": "http://iiif.io/api/image/2/context.json",
                            "@id": $iiif:IMAGE_API_BASE || "/" || $id,
                            "profile": "http://iiif.io/api/image/2/level2.json"
                        }
                    },
                    "on": "https://e-editiones.org/canvas/page-" || $pb/@n || ".json"
                }
            ]
        }
};

(:~
 : Generate a IIIF presentation manifest. Assumes that the source TEI document
 : has pb elements with a facs attribute pointing to the image.
 :)
declare function iiif:manifest($request as map(*)) {
    let $id := $request?parameters?path
    let $doc := config:get-document($id)/tei:TEI
    let $canvases := iiif:canvases($doc)
    return
        map {
            "@context": "http://iiif.io/api/presentation/2/context.json",
            "@id": "https://e-editiones.org/manifest.json",
            "@type": "sc:Manifest",
            "label": $doc//tei:titleStmt/tei:title[@type="distinctive"]/string(),
            "metadata": [
                map { "label": "Title", "value": nav:get-metadata($doc, "title")/string() },
                map { "label": "Creator", "value": nav:get-metadata($doc, "author")/string() }
            ],
            "license": nav:get-metadata($doc, "license"),
            "sequences": [
                map {
                    "@type": "sc:Sequence",
                    "canvases": array { $canvases }
                }
            ]
        }
};