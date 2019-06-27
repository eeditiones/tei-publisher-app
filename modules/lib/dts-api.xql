(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "/db/apps/tei-publisher/modules/config.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

declare variable $local:BASE_PATH :=
    let $appLink := substring-after($config:app-root, repo:get-root())
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "api", "dts"), "/")
    return
        replace($path, "/+", "/");

declare function local:base-endpoint() {
    map {
        "@type": "EntryPoint",
        "collections": $local:BASE_PATH || "/collections",
        "@id": "/api/dts",
        "navigation": $local:BASE_PATH || "/navigation",
        "@context": "dts/EntryPoint.jsonld",
        "documents": $local:BASE_PATH || "/documents"
    }
};

declare function local:collection() {
    let $id := request:get-parameter("id", "default")
    let $collectionInfo := $config:dts-collections($id)
    let $members := local:get-members($collectionInfo)
    return
        map {
            "@context": map {
                "@vocab": "https://www.w3.org/ns/hydra/core#",
                "dc": "http://purl.org/dc/terms/",
                "dts": "https://w3id.org/dts/api#"
            },
            "@type": "Collection",
            "title": $collectionInfo?title,
            "totalItems": count($members),
            "member": array { $members }
        }
};

declare function local:get-members($collectionInfo as map(*)) {
    for $resource in xmldb:get-child-resources($collectionInfo?path)
    where xmldb:get-mime-type(xs:anyURI($collectionInfo?path || "/" || $resource)) = "application/xml"
    return
        map:merge((
            map {
                "@id": $resource,
                "title": $resource,
                "@type": "Resource",
                "dts:passage": $local:BASE_PATH || "/documents?id=" || $collectionInfo?path || "/" || $resource
            },
            $collectionInfo?metadata(doc($collectionInfo?path || "/" || $resource))
        ))
};

declare function local:documents() {
    let $id := request:get-parameter("id", ())
    return (
        util:declare-option("output:method", "xml"),
        util:declare-option("output:media-type", "application/tei+xml"),
        doc($id)
    )
};


let $endpoint := request:get-parameter("endpoint", ())
return
    if (not($endpoint)) then
        local:base-endpoint()
    else
        switch ($endpoint)
            case "documents" return
                local:documents()
            default return
                local:collection()
