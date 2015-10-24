(: 
 : Copyright 2015, Wolfgang Meier
 : 
 : This software is dual-licensed: 
 : 
 : 1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
 : http://creativecommons.org/licenses/by-sa/3.0/ 
 : 
 : 2. http://www.opensource.org/licenses/BSD-2-Clause 
 : 
 : All rights reserved. Redistribution and use in source and binary forms, with or without 
 : modification, are permitted provided that the following conditions are met: 
 : 
 : * Redistributions of source code must retain the above copyright notice, this list of 
 : conditions and the following disclaimer. 
 : * Redistributions in binary form must reproduce the above copyright
 : notice, this list of conditions and the following disclaimer in the documentation
 : and/or other materials provided with the distribution. 
 : 
 : This software is provided by the copyright holders and contributors "as is" and any 
 : express or implied warranties, including, but not limited to, the implied warranties 
 : of merchantability and fitness for a particular purpose are disclaimed. In no event 
 : shall the copyright holder or contributors be liable for any direct, indirect, 
 : incidental, special, exemplary, or consequential damages (including, but not limited to, 
 : procurement of substitute goods or services; loss of use, data, or profits; or business
 : interruption) however caused and on any theory of liability, whether in contract,
 : strict liability, or tort (including negligence or otherwise) arising in any way out
 : of the use of this software, even if advised of the possibility of such damage.
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace app="$$namespace$$" at "app.xql";
import module namespace pages="$$pages-namespace$$" at "pages.xql";
import module namespace config="$$config-namespace$$" at "config.xqm";

declare boundary-space strip;

declare option output:method "json";
declare option output:media-type "application/json";


(: 
 : This module is called from Javascript when the user wants to navigate to the next/previous
 : page.
 :)
let $doc := request:get-parameter("doc", ())
let $root := request:get-parameter("root", ())
let $id := request:get-parameter("id", ())
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
        let $prev := pages:get-previous(if ($parent and (empty($prevDiv) or $xml/.. >> $prevDiv)) then $xml/.. else $prevDiv)
        let $next := pages:get-next($xml)
        let $html := pages:process-content(pages:get-content($xml))
        let $doc := replace($doc, "^.*/([^/]+)$", "$1")
        return
            map {
                "doc": $doc,
                "odd": $config:odd,
                "next": 
                    if ($next) then 
                        $doc || "?root=" || util:node-id($next) || "&amp;odd=" || $config:odd
                    else (),
                "previous": 
                    if ($prev) then 
                        $doc || "?root=" || util:node-id($prev) || "&amp;odd=" || $config:odd
                    else (),
                "content": serialize($html,
                    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                      <output:indent>no</output:indent>
                    </output:serialization-parameters>)
            }
    else
        map { "error": "Not found" }