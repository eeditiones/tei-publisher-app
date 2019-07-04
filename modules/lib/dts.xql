(:
 :
 :  Copyright (C) 2019 Wolfgang Meier
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

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace http = "http://expath.org/ns/http-client";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace dts="https://w3id.org/dts/api#";

declare option output:method "json";
declare option output:media-type "application/ld+json";

declare function local:store-temp($data as node()*, $name as xs:string) {
    let $tempCol :=
        if (xmldb:collection-available($config:data-root || "/dts")) then
            $config:data-root || "/dts"
        else
            xmldb:create-collection($config:data-root, "dts")
    return
        xmldb:store($tempCol, $name, $data, "application/xml")
};

declare function local:import($data as node()*, $name as xs:string) {
    xmldb:store($config:data-default, $name, $data, "application/xml")
};

declare function local:clear-temp() {
    let $docs := collection($config:data-root || "/dts")
    let $until := current-dateTime() - xs:dayTimeDuration("P1D")
    for $outdated in xmldb:find-last-modified-until($docs, $until)
    return
        xmldb:remove(util:collection-name($outdated), util:document-name($outdated))
};

declare function local:import($uri as xs:string, $id as xs:string, $toTemp as xs:boolean?) {
    local:clear-temp(),
    let $request := <http:request method="GET" href="{$uri}"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then (
            let $stored :=
                if ($toTemp) then
                    local:store-temp(tail($response), util:hash($id, "md5") || ".xml")
                else
                    local:import(tail($response), util:hash($id, "md5") || ".xml")
            return
                map {
                    "path": substring-after($stored, $config:data-root || "/")
                }
        )
        else
            response:set-status-code($response[1]/@status)
};

let $dtsConfig := map {
    "app-root": $config:app-root,
    "dts-collections": $config:dts-collections,
    "dts-page-size": $config:dts-page-size,
    "default-odd": $config:default-odd,
    "view": $config:default-view,
    "template": $config:default-template
}
let $preview := request:get-parameter("preview", ())
let $import := request:get-parameter("import", ())
let $id := request:get-parameter("id", ())
return
    if ($preview) then
        local:import($preview, $id, true())
    else if ($import) then
        local:import($import, $id, false())
    else
        dts:process($dtsConfig)
