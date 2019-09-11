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

declare option output:method "json";
declare option output:media-type "application/json";

let $odd := (request:get-parameter("odd", ()), session:get-attribute($config:session-prefix || ".odd"), $config:odd)[1]
let $allOdds :=
    dbutil:scan-resources(xs:anyURI($config:odd-root), function ($resource) {
        if (not(matches($resource, '.*(tei_simplePrint|docx)\.odd$')) and ends-with($resource, ".odd")) then
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
return
    array {
        for $odd in $allOdds
        order by $odd?label
        return
            $odd
    }
