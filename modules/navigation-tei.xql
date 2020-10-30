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

module namespace nav="http://www.tei-c.org/tei-simple/navigation/tei";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare function nav:get-root($root as xs:string?, $options as map(*)?) {
    $config:data-default ! (
        for $doc in collection(. || "/" || $root)//tei:text[ft:query(., "file:*", $options)]
        return
            $doc/ancestor::tei:TEI
    )
};

declare function nav:get-header($config as map(*), $node as element()) {
    $node/tei:teiHeader
};

declare function nav:get-section-for-node($config as map(*), $node as element()) {
    $node/ancestor-or-self::tei:div[count(ancestor::tei:div) < $config?depth][1]
};

declare function nav:get-section($config as map(*), $doc) {
    if ($doc instance of element(tei:div)) then
        $doc
    else
        let $div := ($doc//tei:div)[1]
        return
            if ($div) then
                $div
            else
                let $group := root($doc)/tei:TEI/tei:text/tei:group/tei:text
                return
                    if ($group) then
                        $group[1]
                    else
                        root($doc)/tei:TEI//tei:text
};

declare function nav:get-document-title($config as map(*), $root as element()) {
    nav:get-metadata($config, $root, "title")
};

declare function nav:get-metadata($config as map(*), $root as element(), $field as xs:string) {
    switch ($field)
        case "title" return
            let $header := $root/tei:teiHeader
            return
            (
                $header//tei:msDesc/tei:head, $header//tei:titleStmt/tei:title[@type = 'main'],
                $header//tei:titleStmt/tei:title
            )[1]
        case "author" return (
            $root/tei:teiHeader//tei:titleStmt/tei:author,
            $root/tei:teiHeader//tei:correspDesc/tei:correspAction/tei:persName
        )
        case "language" return
            ($root/@xml:lang/string(), $root/tei:teiHeader/@xml:lang/string(), "en")[1]
        case "date" return (
            $root/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:date,
            $root/tei:teiHeader/tei:publicationStmt/tei:date
        )[1]
        case "license" return
            $root/tei:teiHeader/tei:fileDesc/tei:publicationStmt//tei:licence/@target/string()
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
    let $pb := ($data//tei:pb)[1]
    return
        if ($pb) then
            $pb
        else
            $data/tei:TEI//tei:text
};


declare function nav:get-content($config as map(*), $div as element()) {
    typeswitch ($div)
        case element(tei:teiHeader) return
            $div
        case element(tei:pb) return
            let $nextPage := $div/following::tei:pb[1]
            let $chunk :=
                nav:milestone-chunk($div, $nextPage,
                    if ($nextPage) then
                        ($div/ancestor::* intersect $nextPage/ancestor::*)[last()]
                    else
                      (: if there's only one pb in the document, it's whole
                      text part should be returned :)
                      if (count($div/ancestor::tei:text//tei:pb) = 1) then
                          ($div/ancestor::tei:text)
                      else
                        ($div/ancestor::tei:div, $div/ancestor::tei:text)[1]
                )
            return
                $chunk
        case element(tei:div) return
            nav:fill($config, $div)
        default return
            $div
};

declare function nav:get-subsections($config as map(*), $root as node()) {
    $root//tei:div[tei:head] except $root//tei:div[tei:head]//tei:div
};

declare function nav:get-section-heading($config as map(*), $section as node()) {
    $section/tei:head
};

declare function nav:is-filler($config as map(*), $div) {
    let $parent := $div/ancestor::tei:div[count(ancestor-or-self::tei:div) <= $config?depth][1]
    return
        if ($parent and nav:filler($config, $parent)/descendant-or-self::tei:div[. is $div]) then
            $parent
        else
            ()
};

(:~
 : By-division view:
 : Return additional content to fill up a parent division which otherwise would not have
 : enough text to show. By default adds the first subdivision.
 :)
declare function nav:filler($config as map(*), $div) {
    let $child := $div/tei:div[1]
    return
        if ($config?fill > 0 and $child and count(($child)/preceding-sibling::*/descendant-or-self::*) < $config?fill) then
            $child
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
    if ($div/tei:div and $config?fill > 0 and count($div/ancestor-or-self::tei:div) < $config?depth) then
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
                    util:expand($div/tei:div[1]/preceding-sibling::*, "add-exist-id=all")
                }
    else
        $div
};

(:~
 : By-division view: compute and return the next division to show in sequence.
 :)
declare function nav:next-page($config as map(*), $div) {
    let $filled := nav:filler($config, $div)
    return
        if ($filled) then
            $filled/following::tei:div[1]
        else
            (
                $div/descendant::tei:div[count(ancestor-or-self::tei:div) <= $config?depth],
                $div/following::tei:div[count(ancestor-or-self::tei:div) <= $config?depth]
            )[1]
};

(:~
 : By-division view: compute and return the previous division to show in sequence.
 :)
declare function nav:previous-page($config as map(*), $div) {
    let $preceding := $div/preceding::tei:div[count(ancestor-or-self::tei:div) <= $config?depth][1]
    let $parent := $div/ancestor::tei:div[1]
    let $previous := if ($preceding << $parent) then $parent else $preceding
    return
        if ($previous) then
            (: Check if the section would be displayed together with any of its ancestors.
             : For this we need to traverse the tree upwards and check each ancestor.
             :)
            let $nearest := filter(
                $previous/ancestor-or-self::tei:div[count(ancestor-or-self::tei:div) <= $config?depth], 
                function($ancestor) {
                    exists(nav:filler($config, $ancestor)/descendant-or-self::tei:div[. is $previous])
                }
            )
            return
                if ($nearest) then
                    $nearest
                else
                    $previous
        else
            $div/ancestor::tei:div[1]
};

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    let $next :=
        switch ($view)
            case "page" return
                $div/following::tei:pb[1]
            case "body" return
                ($div/following-sibling::*, $div/../following-sibling::*)[1]
            default return
                nav:next-page($config, $div)
    return
        if (empty($config?context) or $config?context instance of document-node() or $next/ancestor::*[. is $config?context]) then
            $next
        else
            ()
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    let $previous :=
        switch ($view)
            case "page" return
                $div/preceding::tei:pb[1]
            case "body" return
                ($div/preceding-sibling::*, $div/../preceding-sibling::*)[1]
            default return
                nav:previous-page($config, $div)
    return
        if ($config?context instance of document-node() or $previous/ancestor::*[. is $config?context]) then
            $previous
        else
            ()
};

declare function nav:milestone-chunk($ms1 as element(), $ms2 as element()?, $node as node()*) as node()* {
    let $descendantCheck :=
        if ($ms1 instance of element(tei:pb) and (empty($ms2) or $ms2 instance of element(tei:pb))) then
            function($node, $ms1, $ms2) {
                $node/descendant::tei:pb intersect ($ms1, $ms2)
            }
        else
            function($node, $ms1, $ms2) {
                some $n in $node/descendant::* satisfies ($n is $ms1 or $n is $ms2)
            }
    return
        nav:milestone-chunk($ms1, $ms2, $node, $descendantCheck)
};

declare function nav:milestone-chunk($ms1 as element(), $ms2 as element()?, $node as node()*,
    $descendantCheck as function(*)) as node()*
{
    typeswitch ($node)
        case element() return
            if ($node is $ms1) then
                util:expand($node, "add-exist-id=all")
            else if ( $descendantCheck($node, $ms1, $ms2) ) then
                element { node-name($node) } {
                    $node/@*,
                    for $i in ( $node/node() )
                    return nav:milestone-chunk($ms1, $ms2, $i, $descendantCheck)
                }
            else if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then
                util:expand($node, "add-exist-id=all")
            else
                ()
        case attribute() return
            $node (: will never match attributes outside non-returned elements :)
        default return
            if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then $node
            else ()
};