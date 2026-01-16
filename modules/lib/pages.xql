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

(:~
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    for $data in config:get-document($doc)
    return
        if (exists($data)) then
            pages:load-xml($data, $view, $root, $doc)
        else
            ()
};

declare function pages:load-xml($data as node()*, $view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $config :=
        (: parse processing instructions and remember original context :)
        map:merge((tpu:parse-pi(root($data[1]), $view), map { "context": $data }))
    return
        map {
            "config": $config,
            "data":
                switch ($config?view)
            	    case "div" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return
                                nav:get-section-for-node($config, $node)
                        else
                            nav:get-section($config, $data)
                    case "page" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            nav:get-first-page-start($config, $data)
                    case "single" return
                        $data
                    default return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data/tei:TEI/tei:text
        }
};

declare function pages:process-content($xml as node()*, $root as node()*, $config as map(*), $userParams as map(*)?, $wrap as xs:boolean?) {
    let $params := map:merge((
            map {
                "root": $root,
                "view": $config?view,
                "context-path": $config:context-path
            },
            $userParams))
	let $html := $pm-config:web-transform($xml, $params, $config?odd)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    let $body := pages:clean-footnotes($html)
    let $footnotes := 
        for $fn in $html//*[@class = "footnote"]
        return
            element { node-name($fn) } {
                $fn/@*,
                pages:clean-footnotes($fn/node())
            }
    let $content := (
        $body,
            if ($footnotes) then
                nav:output-footnotes($footnotes)
            else
                ()
            ,
            $html//paper-tooltip
    )
    return
        if ($wrap or count($content) > 1) then
            <div class="{$config:css-content-class} {$class}">
            { $content }
            </div>
        else
            $content
};

declare function pages:clean-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(paper-tooltip) return
		        ()
            case element() return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        pages:clean-footnotes($node/node())
                    }
            default return
                $node
};

declare function pages:get-content($config as map(*), $div as element()) {
    nav:get-content($config, $div)
};

declare function pages:switch-view-id($data as element()+, $view as xs:string) {
    let $root :=
        if ($view = "div") then
            ($data/*[1][self::tei:pb], $data/preceding::tei:pb[1])[1]
        else
            ($data/ancestor::tei:div, $data/following::tei:div, $data/ancestor::tei:body, $data/ancestor::tei:front)[1]
    return
        $root
};