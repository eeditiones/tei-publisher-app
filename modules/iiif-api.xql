
module namespace iiif="https://e-editiones.org/api/iiif";

import module namespace iiifc="https://e-editiones.org/api/iiif/config" at "iiif-config.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ Contact the IIIF image api to get the dimensions of an image :)
declare %private function iiif:image-info($path as xs:string) {
    let $request := <http:request method="GET" href="{string-join(($iiifc:IMAGE_API_BASE, $path), '/')}/info.json"/>
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
            "label":  'Page ' || $pb/@n,
            "width": $info?width,
            "height": $info?height,
            "images": [
                map {
                    "@type": "oa:Annotation",
                    "motivation": "sc:painting",
                    "resource": map {
                        "@id": string-join(($iiifc:IMAGE_API_BASE, $id), '/') || "/full/max/0/default.jpg",
                        "@type": "dctypes:Image",
                        "format": "image/jpeg",
                        "width": $info?width,
                        "height": $info?height,
                        "service": map {
                            "@context": "http://iiif.io/api/image/2/context.json",
                            "@id": string-join(($iiifc:IMAGE_API_BASE, $id), '/'),
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
    let $document := config:get-document($id)

    let $doc :=
        typeswitch ($document)
            case document-node() return
                $document/child::*
            default return
                $document
    
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

(:~
 : Get the facsimiles that are relevant for the given document file
 :)
declare function iiif:facsimiles ($request as map(*)) {
    let $id := $request?parameters?path
    let $document := config:get-document($id)
    let $milestones := iiifc:milestones($document)
    let $entries := for $milestone in $milestones
      return map:entry(($milestone/@facs, $milestone/@url)[1], $iiifc:IMAGE_API_BASE || iiifc:milestone-id($milestone))
    return map:merge($entries)
};
