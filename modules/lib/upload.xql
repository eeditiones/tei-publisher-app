xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace docx="http://existsolutions.com/teipublisher/docx";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

declare function local:upload($root, $paths, $payloads) {
    for-each-pair($paths, $payloads, function($path, $data) {
        try {
            let $path :=
                if (ends-with($path, ".docx")) then
                    let $mediaPath := $config:data-root || "/" || $root || "/" || xmldb:encode($path) || ".media"
                    let $stored := xmldb:store($config:data-root || "/" || $root, xmldb:encode($path), $data)
                    let $tei :=
                        docx:process($stored, $config:data-root, $pm-config:tei-transform, "docx.odd", $mediaPath)
                    return
                        xmldb:store($config:data-root || "/" || $root, xmldb:encode($path) || ".xml", $tei)
                else if (ends-with($path, ".odd")) then
                    xmldb:store($config:odd-root, xmldb:encode($path), $data)
                else
                    xmldb:store($config:data-root || "/" || $root, xmldb:encode($path), $data)
            return
                map {
                    "name": $path,
                    "path": substring-after($path, $config:data-root || "/"),
                    "type": xmldb:get-mime-type($path),
                    "size": 93928
                }
        } catch * {
            response:set-status-code(500),
            $err:description
        }
    })
};

let $name := request:get-uploaded-file-name("files[]")
let $data := request:get-uploaded-file-data("files[]")
let $root := request:get-parameter("root", ())
return
    try {
        local:upload($root, $name, $data)
    } catch * {
        map {
            "name": $name,
            "error": $err:description
        }
    }
