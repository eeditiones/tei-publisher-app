xquery version "3.1";

module namespace dts="http://teipublisher.com/api/dts";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace router="http://e-editiones.org/roaster";

declare %private function dts:base-path() {
    let $appLink := substring-after($config:app-root, repo:get-root())
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "api", "dts"), "/")
    return
        replace($path, "/+", "/")
};

declare function dts:base-endpoint($request as map(*)) {
    let $base := dts:base-path()
    return
        map {
            "@type": "EntryPoint",
            "collections": $base || "/collections",
            "@id": "/api/dts",
            "navigation": $base || "/navigation",
            "@context": "dts/EntryPoint.jsonld",
            "documents": $base || "/document"
        }
};

declare function dts:collection($request as map(*)) {
    let $collectionInfo :=
        if ($request?parameters?id) then
            dts:collection-by-id($config:dts-collections, $request?parameters?id, (), $request?parameters?nav = "parents")
        else
            $config:dts-collections
    return
        if (exists($collectionInfo)) then
            let $resources := if (map:contains($collectionInfo, "members")) then $collectionInfo?members() else ()
            let $pageSize := xs:int(($request?parameters?per-page, $config:dts-page-size)[1])
            let $count := count($resources)
            let $paged := subsequence($resources, ($request?parameters?page - 1) * $pageSize + 1, $pageSize)
            let $memberResources := dts:get-members($collectionInfo, $paged)
            let $memberCollections := dts:get-members($collectionInfo, $collectionInfo?memberCollections)
            let $parentInfo := 
                if ($request?parameters?id) then
                    dts:collection-by-id($config:dts-collections, $request?parameters?id, (), true())
                else
                    ()
            return
                map {
                    "@context": map {
                        "@vocab": "https://www.w3.org/ns/hydra/core#",
                        "dc": "http://purl.org/dc/terms/",
                        "dts": "https://w3id.org/dts/api#"
                    },
                    "@type": "Collection",
                    "@id": $collectionInfo?id,
                    "title": $collectionInfo?title,
                    "totalItems": $count,
                    "dts:totalChildren": $count,
                    "dts:totalParents": count($parentInfo),
                    "member": array { $memberResources, $memberCollections }
                }
        else
            response:set-status-code(404)
};

declare %private function dts:collection-by-id($collectionInfo as map(*), $id as xs:string, $parentInfo as map(*)?, 
    $returnParent as xs:boolean?) {
    if ($collectionInfo?id = $id) then
        if ($returnParent) then $parentInfo else $collectionInfo
    else
        for $member in $collectionInfo?memberCollections
        return
            dts:collection-by-id($member, $id, $collectionInfo, $returnParent)
};

declare %private function dts:get-members($collectionInfo as map(*), $resources as item()*) {
    for $resource in $resources
    return
        typeswitch($resource)
            case map(*) return
                map {
                    "@id": $resource?id,
                    "title": $resource?title,
                    "@type": "Collection"
                }
            default return
                let $id := substring-after(document-uri(root($resource)), $collectionInfo?path || "/")
                return
                    map:merge((
                        map {
                            "@id": $collectionInfo?id || "/" || $id,
                            "title": $id,
                            "@type": "Resource",
                            "dts:passage": dts:base-path() || "/document?id=" || $collectionInfo?path || "/" || $id
                        },
                        $collectionInfo?metadata(root($resource))
                    ))
};

declare function dts:documents($request as map(*)) {
    let $doc := 
        if (starts-with($request?parameters?id, "/")) then
            doc($request?parameters?id)
        else
            doc($config:data-root || "/" || $request?parameters?id)
    return
        if ($doc) then (
            util:declare-option("output:method", "xml"),
            util:declare-option("output:media-type", "application/tei+xml"),
            dts:check-pi($doc)
        ) else
            response:set-status-code(404)
};

declare %private function dts:check-pi($doc as document-node()) {
    let $pi := $doc/processing-instruction("teipublisher")
    return
        if ($pi) then
            $doc
        else
            let $config := config:default-config(document-uri($doc))
            return
                document {
                    processing-instruction teipublisher {
                        ``[odd="`{$config?odd}`" view="`{$config?view}`" template="`{$config?template}`"]``
                    },
                    $doc/node()
                }
};

declare %private function dts:store-temp($data as node()*, $name as xs:string) {
    let $tempCol :=
        if (xmldb:collection-available($config:data-root || "/dts")) then
            $config:data-root || "/dts"
        else
            xmldb:create-collection($config:data-root, "dts")
    return
        xmldb:store($tempCol, $name, $data, "application/xml")
};

declare %private function dts:store($data as node()*, $name as xs:string) {
    xmldb:store($config:dts-import-collection, $name, $data, "application/xml")
};

declare %private function dts:clear-temp() {
    let $docs := collection($config:data-root || "/dts")
    let $until := current-dateTime() - xs:dayTimeDuration("P1D")
    for $outdated in xmldb:find-last-modified-until($docs, $until)
    return
        xmldb:remove(util:collection-name($outdated), util:document-name($outdated))
};

declare function dts:import($request as map(*)) {
    dts:clear-temp(),
    let $options := <http:request method="GET" href="{$request?parameters?uri}"/>
    let $response := http:send-request($options)
    return
        if ($response[1]/@status = "200") then (
            let $stored :=
                if ($request?parameters?temp) then
                    dts:store-temp(tail($response), util:hash($request?parameters?uri, "md5") || ".xml")
                else
                    dts:store(tail($response), util:hash($request?parameters?uri, "md5") || ".xml")
            return
                router:response(201, "application/json",
                    map {
                        "path": substring-after($stored, $config:data-root || "/")
                    }
                )
        )
        else
            response:set-status-code($response[1]/@status)
};