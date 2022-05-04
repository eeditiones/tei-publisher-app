xquery version "3.1";

module namespace iapi="http://teipublisher.com/api/info";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";

declare function iapi:version($request as map(*)) {
    map {
        "api": $request?info?version,
        "app": map {
            "name": $config:expath-descriptor/@abbrev/string(),
            "version": $config:expath-descriptor/@version/string()
        },
        "engine": map {
            "name": system:get-product-name(),
            "version": system:get-version()
        }
    }
};

declare function iapi:list-templates($request as map(*)) {
    array {
        for $html in collection($config:app-root || "/templates/pages")/*
        let $description := $html//meta[@name="description"]/@content/string()
        return
            map {
                "name": util:document-name($html),
                "title": $description
            }
    }
};