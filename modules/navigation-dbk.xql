(:
 :
 :  Copyright (C) 2017 Wolfgang Meier
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

module namespace nav="http://www.tei-c.org/tei-simple/navigation/docbook";

declare namespace dbk="http://docbook.org/ns/docbook";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare function nav:get-root($root as xs:string?, $options as map(*)?) {
    $config:data-root !
        collection(. || "/" || $root)//dbk:article[ft:query(., "db-file:*", $options)]
};

declare function nav:get-header($config as map(*), $node as element()) {
    $node/dbk:info
};

declare function nav:get-section-for-node($config as map(*), $node as element()) {
    $node/ancestor-or-self::dbk:section[count(ancestor::dbk:section) < $config?depth][1]
};

declare function nav:get-section($config as map(*), $doc) {
    ($doc//dbk:section)[1]
};

declare function nav:get-document-title($config as map(*), $root as element()) {
    $root/dbk:info/dbk:title/string()
};

declare function nav:get-metadata($config as map(*), $root as element(), $field as xs:string) {
    switch ($field)
        case "title" return
            nav:get-document-title($config, $root)
        case "author" return
            $root/dbk:info/dbk:author/string()
        case "date" return
            $root/dbk:info/(dbk:pubdate|dbk:copyright/dbk:year|dbk:date)[1]
        case "language" return
            ($root/@xml:lang/string(), "en")[1]
        default return
            ()
};

declare function nav:sort($sortBy as xs:string, $items as element()*) {
    switch ($sortBy)
        case "date" return
            sort($items, (), ft:field(?, "date", "xs:date"))
        default return
            sort($items, 'http://www.w3.org/2013/collation/UCA', ft:field(?, $sortBy))
};

declare function nav:get-first-page-start($config as map(*), $data as element()) {
    ()
};

(:~
 : By-division view:
 : Return additional content to fill up a parent division which otherwise would not have
 : enough text to show. By default adds the first subdivision.
 :)
declare function nav:filler($config as map(*), $div) {
    if ($config?fill > 0 and $div/dbk:section and count(($div/dbk:section[1])/preceding-sibling::*/descendant-or-self::*) < $config?fill) then
        $div/dbk:section[1]
    else
        ()
};

(:~
 : By-division view: get the top fragment to display for the division. If the division is on a level
 : above the configured max depth, sub-divisions will be shown on their own page - except if the
 : content before the first child division is less than the number of elements configured for the
 : fill parameter. In this case, the first sub-division will be shown together with its parent.
 :)
declare function nav:fill($config as map(*), $div) {
    if ($div/dbk:section and $config?fill > 0 and count($div/ancestor-or-self::dbk:section) < $config?depth) then
        let $filler := nav:filler($config, $div)
        return
            if ($filler) then
                element { node-name($div) } {
                    $div/@* except $div/@exist:id,
                    attribute exist:id { util:node-id($div) },
                    util:expand(($filler/preceding-sibling::node(), $filler), "add-exist-id=all")
                }
            else
                element { node-name($div) } {
                    $div/@* except $div/@exist:id,
                    attribute exist:id { util:node-id($div) },
                    util:expand($div/dbk:section[1]/preceding-sibling::*, "add-exist-id=all")
                }
    else
        $div
};

declare function nav:is-filler($config as map(*), $div) {
    let $parent := $div/ancestor::dbk:section[count(ancestor-or-self::dbk:section) <= $config?depth][1]
    return
        if ($parent and nav:filler($config, $parent)/descendant-or-self::dbk:section[. is $div]) then
            $parent
        else
            ()
};

(:~
 : By-division view: compute and return the next division to show in sequence.
 :)
declare function nav:next-page($config as map(*), $div) {
    let $filled := nav:filler($config, $div)
    return
        if ($filled) then
            $filled/following::dbk:section[1]
        else
            (
                $div/descendant::dbk:section[count(ancestor-or-self::dbk:section) <= $config?depth],
                $div/following::dbk:section[count(ancestor-or-self::dbk:section) <= $config?depth]
            )[1]
};

(:~
 : By-division view: compute and return the previous division to show in sequence.
 :)
declare function nav:previous-page($config as map(*), $div) {
    let $preceding := $div/preceding::dbk:section[count(ancestor-or-self::dbk:section) <= $config?depth][1]
    let $parent := $div/ancestor::dbk:section[1]
    let $previous := if ($preceding << $parent) then $parent else $preceding
    return
        if ($previous) then
            (: Check if the section would be displayed together with any of its ancestors.
             : For this we need to traverse the tree upwards and check each ancestor.
             :)
            let $nearest := filter(
                $previous/ancestor-or-self::dbk:section[count(ancestor-or-self::dbk:section) <= $config?depth], 
                function($ancestor) {
                    exists(nav:filler($config, $ancestor)/descendant-or-self::dbk:section[. is $previous])
                }
            )[1]
            return
                if ($nearest) then
                    $nearest
                else
                    $previous
        else
            $div/ancestor::dbk:section[1]
};

declare function nav:get-content($config as map(*), $div as element()) {
    typeswitch($div)
        case element(dbk:section) return
            nav:fill($config, $div)
        default return
            $div
};

declare function nav:get-subsections($config as map(*), $root as node()) {
    $root//dbk:section[dbk:title] except $root//dbk:section[dbk:title]//dbk:section
};

declare function nav:get-section-heading($config as map(*), $section as node()) {
    $section/dbk:title
};

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    let $next := nav:next-page($config, $div)
    return
        if (empty($config?context) or $config?context instance of document-node() or $next/ancestor::*[. is $config?context]) then
            $next
        else
            ()
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    let $previous := nav:previous-page($config, $div)
    return
        if ($config?context instance of document-node() or $previous/ancestor::*[. is $config?context]) then
            $previous
        else
            ()
};