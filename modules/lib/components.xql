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

import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace nav-tei="http://www.tei-c.org/tei-simple/navigation/tei" at "../navigation-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace mapping="http://www.tei-c.org/tei-simple/components/map" at "../map.xql";

declare boundary-space strip;

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:extract-footnotes($html as element()*) {
    map {
        "footnotes": $html/div[@class="footnotes"],
        "content":
            element { node-name($html) } {
                $html/@*,
                $html/node() except $html/div[@class="footnotes"]
            }
    }
};

(:
 : This module is called from Javascript when the user wants to navigate to the next/previous
 : page.
 :)
let $doc := request:get-parameter("doc", ())
let $root := request:get-parameter("root", ())
let $id := request:get-parameter("id", () )
let $view := request:get-parameter("view", $config:default-view)
let $xpath := request:get-parameter("xpath", ())
let $debug := request:get-parameter("debug", ())
let $mapping := request:get-parameter("map", ())
let $highlight := request:get-parameter("highlight", ())
let $xml :=
    if ($xpath) then
        for $document in pages:get-document($doc)
        let $namespace := namespace-uri-from-QName(node-name($document/*))
        let $xquery := "declare default element namespace '" || $namespace || "'; $document" || $xpath
        let $data := util:eval($xquery)
        return
            if ($data) then
                pages:load-xml($data, $view, $root, $doc)
            else
                ()

    else if (exists($id)) then (
        for $document in pages:get-document($doc)
        let $config := tpu:parse-pi($document, $view)
        let $data :=
            if (count($id) = 1) then
                nav:get-section-for-node($config, $document/id($id))
            else
                let $ms1 := $document/id($id[1])
                let $ms2 := $document/id($id[2])
                return
                    if ($ms1 and $ms2) then
                        nav-tei:milestone-chunk($ms1, $ms2, $document/tei:TEI)
                    else
                        ()
        return
            map {
                "config": map:merge(($config, map { "context": $document })),
                "odd": $config?odd,
                "view": $config?view,
                "data": $data
            }
    ) else
        pages:load-xml($view, $root, $doc)
return
    if ($xml?data) then
        let $userParams :=
          map:merge((
              request:get-parameter-names()[starts-with(., 'user')] ! map { substring-after(., 'user.'): request:get-parameter(., ()) },
              map { "webcomponents": 6 }
          ))
        let $mapped :=
            if ($mapping) then
                let $mapFun := function-lookup(xs:QName("mapping:" || $mapping), 2)
                let $mapped := $mapFun($xml?data, $userParams)
                return
                    $mapped
            else
                $xml?data
        let $data :=
            if (empty($xpath) and $highlight and exists(session:get-attribute($config:session-prefix || ".query"))) then
                query:expand($xml?config, $mapped)[1]
            else
                $mapped
        let $content :=
            if (not($view = "single")) then
                pages:get-content($xml?config, $data)
            else
                $data

        let $html :=
            typeswitch ($mapped)
                case element() | document-node() return
                    pages:process-content($content, $xml?data, $xml?config, $userParams)
                default return
                    $content
        let $transformed := local:extract-footnotes($html[1])
        let $doc := replace($doc, "^.*/([^/]+)$", "$1")
        return
            if ($debug) then (
                util:declare-option("output:method", "html5"),
                util:declare-option("output:media-type", "text/html"),
                $transformed?content
            ) else
                map {
                    "view": $view,
                    "doc": $doc,
                    "root": $root,
                    "odd": $xml?config?odd,
                    "next":
                        if ($view != "single") then
                            let $next := $config:next-page($xml?config, $xml?data, $view)
                            return
                                if ($next) then
                                    util:node-id($next)
                                else ()
                        else
                            (),
                    "previous":
                        if ($view != "single") then
                            let $prev := $config:previous-page($xml?config, $xml?data, $view)
                            return
                                if ($prev) then
                                    util:node-id($prev)
                                else
                                    ()
                        else
                            (),
                    "switchView":
                        if ($view != "single") then
                            let $node := pages:switch-view-id($xml?data, $view)
                            return
                                if ($node) then
                                    util:node-id($node)
                                else
                                    ()
                        else
                            (),
                    "content": serialize($transformed?content,
                        <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                          <output:indent>no</output:indent>
                        <output:method>html5</output:method>
                            </output:serialization-parameters>),
                    "footnotes": $transformed?footnotes,
                    "userParams": $userParams
                }
    else
        map { "error": "Not found" }
