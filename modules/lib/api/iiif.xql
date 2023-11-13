(:~
 : Open API module to generate a IIIF presentation manifest.
 : By default walks through all pb in the document, using the @facs
 : attribute to resolve images. It contacts the configured image api service
 : to retrieve measurements for each image.
 :
 : While the XQuery code is quite generic, it may need to be adjusted for
 : concrete use-cases.
 :
 : The general assumption is that for each milestone element in the TEI (usually a pb or milestone),
 : a canvas is created, containing one image. The image service URL is generated
 : by appending the string returned by iiif:milestone-id to $iiif:IMAGE_API_BASE.
 : The canvas id will correspond to $iiif:CANVAS_ID_PREFIX with iiif:milestone-id appended.
 :)
module namespace iiif="https://e-editiones.org/api/iiif";

import module namespace iiifc="https://e-editiones.org/api/iiif/config" at "../../iiif-config.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ Contact the IIIF image api to get the dimensions of an image :)
declare %private function iiif:image-info($path as xs:string) {
    let $request := <http:request method="GET" href="{$iiifc:IMAGE_API_BASE}/{$path}/info.json"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = 200) then
            let $data := util:binary-to-string(xs:base64Binary($response[2]))
            return
                parse-json($data)
        else
            ()
};

(:~
 : Create the list of canvases: for each pb element in the document, one canvas is output.
 :)
declare %private function iiif:canvases($doc as node()) {
    for $pb in iiifc:milestones($doc)
    let $id := iiifc:milestone-id($pb)
    let $info := iiif:image-info($id)
    where exists($info)
    return
        map {
            "@id": $iiifc:CANVAS_ID_PREFIX || $id,
            "@type": "sc:Canvas",
            "label": "Page " || $pb/@n,
            "width": $info?width,
            "height": $info?height,
            "images": [
                map {
                    "@type": "oa:Annotation",
                    "motivation": "sc:painting",
                    "resource": map {
                        "@id": $iiifc:IMAGE_API_BASE || "/" || $id || "/full/full/0/default.jpg",
                        "@type": "dctypes:Image",
                        "format": "image/jpeg",
                        "width": $info?width,
                        "height": $info?height,
                        "service": map {
                            "@context": "http://iiif.io/api/image/2/context.json",
                            "@id": $iiifc:IMAGE_API_BASE || "/" || $id,
                            "profile": "http://iiif.io/api/image/2/level2.json"
                        }
                    },
                    "on": $iiifc:CANVAS_ID_PREFIX || $id
                }
            ],
            "rendering": [
                map {
                    "@id": iiif:link("api/parts/" || encode-for-uri(config:get-relpath($doc)) || "/html") || 
                        "?root=" || util:node-id($pb),
                    "format": "text/html",
                    "label": "Transcription of page"
                }
            ]
        }
};

(:~ Generate absolute link to be used in the "rendering" property :)
declare %private function iiif:link($relpath as xs:string) {
    let $host := request:get-scheme() || "://" || request:get-server-name()
    let $port :=
        if (request:get-server-port() = (80, 443)) then
            ()
        else
            ":" || request:get-server-port()
    return
        string-join(($host, $port, replace($config:context-path || "/" || $relpath, "//", "/")))
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
        map:merge((
            map {
                "@context": "http://iiif.io/api/presentation/2/context.json",
                "@id": "https://e-editiones.org/manifest.json",
                "@type": "sc:Manifest",
                "sequences": [
                    map {
                        "@type": "sc:Sequence",
                        "canvases": array { $canvases }
                    }
                ]
            },
            iiifc:metadata($doc, $id)
        ))
};