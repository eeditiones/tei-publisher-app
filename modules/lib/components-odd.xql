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

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace dbutil = "http://exist-db.org/xquery/dbutil";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace obe = "http://exist-db.org/apps/teipublisher/obe" at "../odd-by-example.xql";

declare option output:method "json";
declare option output:media-type "application/json";

declare %private function local:parse-template($nodes as node()*, $odd as xs:string, $title as xs:string?) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node()
                return
                    local:parse-template($node/node(), $odd, $title)
            case element(tei:schemaSpec)
                return
                    element {node-name($node)} {
                        $node/@*,
                        attribute ident {$odd},
                        local:parse-template($node/node(), $odd, $title)
                    }
            case element(tei:title)
                return
                    element {node-name($node)} {
                        $node/@*,
                        $title
                    }
            case element(tei:change)
                return
                    element {node-name($node)} {
                        attribute when {current-date()},
                        "Initial version"
                    }
            case element()
                return
                    element {node-name($node)} {
                        $node/@*,
                        local:parse-template($node/node(), $odd, $title)
                    }
            default
                return
                    $node
};

declare function local:create($new_odd, $title) {
    let $template := doc($config:odd-root || "/template.odd.xml")
    let $parsed := document {local:parse-template($template, $new_odd, $title)}
    let $stored := xmldb:store($config:odd-root, $new_odd || ".odd", $parsed, "text/xml")
    return
        local:compile($new_odd)
};

declare function local:compile($odd) {
    for $module in ("web", "print", "latex", "epub")
    let $result :=
        pmu:process-odd(
            odd:get-compiled($config:odd-root, $odd || ".odd"),
            $config:output-root,
            $module,
            "../" || $config:output,
            $config:module-config
        )
    return
        ()
};

declare function local:create-by-example($new_odd, $title, $examples) {
    (obe:process-example($config:data-default, $new_odd, "all", $examples, $title))[0]
};

declare function local:list($odd) {
    array {
        dbutil:scan-resources(xs:anyURI($config:odd-root), function ($resource) {
            if (ends-with($resource, ".odd")) then
                let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
                let $displayName := (
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "short"]/string(),
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text(),
                    $name
                )[1]
                let $description :=  doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/tei:desc/string()


                return
                    map {
                        "name": $name,
                        "label": $displayName,
                        "description": $description,
                        "path": $resource,
                        "current": ($odd = $name || ".odd")
                    }
            else
                ()
        })
    }
};


let $delete := request:get-parameter("delete", ())
let $new_odd := request:get-parameter("new_odd", ())
let $byExample := request:get-parameter("byExample", ())
let $title := request:get-parameter("title", ())
let $odd := (request:get-parameter("odd", ()), session:get-attribute($config:session-prefix || ".odd"), $config:odd)[1]
let $user := request:get-attribute($config:login-domain || ".user")
return (
    if ($delete) then
        xmldb:remove(replace($delete, "^(.*)/[^/]+$", "$1"), replace($delete, "^.*/([^/]+)$", "$1"))
    else if (exists($byExample)) then
        local:create-by-example($new_odd, $title, $byExample)
    else if ($new_odd) then
        local:create($new_odd, $title)
    else
        (),
    local:list($odd)
)
