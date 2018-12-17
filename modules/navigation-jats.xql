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

module namespace nav="http://www.tei-c.org/tei-simple/navigation/jats";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare function nav:get-header($config as map(*), $node as element()) {
    $node/front/article-meta
};

declare function nav:get-section-for-node($config as map(*), $node as element()) {
    $node/ancestor-or-self::sec[count(ancestor::sec) < $config?depth][1]
};

declare function nav:get-section($config as map(*), $doc) {
    ($doc//sec)[1]
};

declare function nav:get-document-title($config as map(*), $root as element()) {
    $root/front/article-meta/title-group/article-title/string()
};

declare function nav:get-document-metadata($config as map(*), $root as element()) {
    map {
        "title": nav:get-document-title($config, $root),
        "language": ($root/@xml:lang/string(), "en")[1]
    }
};

declare function nav:get-metadata($config as map(*), $root as element(), $field as xs:string) {
    switch ($field)
        case "title" return
            nav:get-document-title($config, $root)
        case "language" return
            ($root/@xml:lang/string(), "en")[1]
        default return
            ()
};

declare function nav:get-content($config as map(*), $div as element()) {
    typeswitch($div)
        case element(sec) return
            if ($div/sec and count($div/ancestor::sec) < $config?depth - 1) then
                if ($config?fill > 0 and
                    count(($div/sec[1])/preceding-sibling::*//*) < $config?fill) then
                    let $child := $div/sec[1]
                    return
                        element { node-name($div) } {
                            $div/@* except $div/@exist:id,
                            attribute exist:id { util:node-id($div) },
                            util:expand(($child/preceding-sibling::*, $child), "add-exist-id=all")
                        }
                else
                    element { node-name($div) } {
                        $div/@* except $div/@exist:id,
                        attribute exist:id { util:node-id($div) },
                        util:expand($div/sec[1]/preceding-sibling::*, "add-exist-id=all")
                    }
            else
                $div
        default return
            $div
};

declare function nav:get-subsections($config as map(*), $root as node()) {
    $root//sec[title] except $root//sec[title]//sec
};

declare function nav:get-section-heading($config as map(*), $section as node()) {
    $section/title
};

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    nav:get-next($config, $div)
};


declare function nav:get-next($config as map(*), $div as element()) {
    if ($div/sec[count(ancestor::sec) < $config?depth]) then
        if ($config?fill > 0 and count(($div/sec[1])/preceding-sibling::*//*) < $config?fill) then
            nav:get-next($config, $div/sec[1])
        else
            $div/sec[1]
    else
        $div/following::sec[1][count(ancestor::sec) < $config?depth]
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    nav:get-previous-div($config, $div)
};

declare function nav:get-previous-div($config as map(*), $div as element()) {
    let $parent := $div/ancestor::sec[not(*[1] instance of element(sec))][1]
    let $prevDiv := $div/preceding::sec[count(ancestor::sec) < $config?depth][1]
    return
        nav:get-previous-recursive(
            $config,
            if ($parent and (empty($prevDiv) or $div/.. >> $prevDiv)) then $div/.. else $prevDiv
        )
};

declare %private function nav:get-previous-recursive($config as map(*), $div as element(sec)?) {
    if (empty($div)) then
        ()
    else
        if (
            empty($div/preceding-sibling::sec)  (: first div in section :)
            and $config?fill > 0
            and count($div/preceding-sibling::*//*) < $config?fill (: less than 5 elements before div :)
            and $div/.. instance of element(sec) (: parent is a div :)
        ) then
            nav:get-previous-recursive($config, $div/ancestor::sec[count(ancestor::sec) < $config?depth][1])
        else
            $div
};

declare function nav:index($config as map(*), $root) {
    ()
};
