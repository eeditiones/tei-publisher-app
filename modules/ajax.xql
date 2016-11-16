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
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";

import module namespace app="http://www.tei-c.org/tei-simple/templates" at "app.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare boundary-space strip;

declare option output:method "json";
declare option output:media-type "application/json";


(: 
 : This module is called from Javascript when the user wants to navigate to the next/previous
 : page.
 :)
let $doc := request:get-parameter("doc", ())
let $root := request:get-parameter("root", ())
let $odd := request:get-parameter("odd", ())
let $id := request:get-parameter("id", ())
let $view := request:get-parameter("view", $config:default-view)
let $xml := 
    if ($id) then (
        console:log("Loading by id " || $id),
        let $node := doc($config:app-root || "/" || $doc)/id($id)
        let $div := $node/ancestor-or-self::tei:div[1]
        return
            if (empty($div)) then
                $node/following-sibling::tei:div[1]
            else
                $div
    ) else
        pages:load-xml("div", $root, $doc)
return
    if ($xml) then
        let $parent := $xml/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
        let $prevDiv := $xml/preceding::tei:div[1]
        let $prev := 
            switch ($view)
                case "page" return
                    $xml/preceding::tei:pb[1]
                case "body" return
                    ($xml/preceding-sibling::*, $xml/../preceding-sibling::*)[1]
                default return
                    let $parent := $xml/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
                    let $prevDiv := $xml/preceding::tei:div[1]
                    return
                        pages:get-previous(if ($parent and (empty($prevDiv) or $xml/.. >> $prevDiv)) then $xml/.. else $prevDiv)
        let $next :=
            switch ($view)
                case "page" return
                    $xml/following::tei:pb[1]
                case "body" return
                    ($xml/following-sibling::*, $xml/../following-sibling::*)[1]
                default return
                    pages:get-next($xml)
        let $html := pages:process-content($odd, pages:get-content($xml), $xml)
        let $doc := replace($doc, "^.*/([^/]+)$", "$1")
        return
            map {
                "doc": $doc,
                "root": $root,
                "odd": $odd,
                "next": 
                    if ($next) then 
                        $doc || "?root=" || util:node-id($next) || "&amp;odd=" || $odd || "&amp;view=" || $view
                    else (),
                "previous": 
                    if ($prev) then 
                        $doc || "?root=" || util:node-id($prev) || "&amp;odd=" || $odd || "&amp;view=" || $view
                    else (),
                "switchView": 
                    let $root := pages:switch-view-id($xml, $view)
                    return
                        if ($root) then
                            $doc || "?root=" || util:node-id($root) || "&amp;odd=" || $odd || 
                                "&amp;view=" || (if ($view = "div") then "page" else "div")
                        else
                            (),
                "content": serialize($html,
                    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                      <output:indent>no</output:indent>
                    </output:serialization-parameters>)
            }
    else
        map { "error": "Not found" }