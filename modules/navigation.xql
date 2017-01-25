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

module namespace nav="http://www.tei-c.org/tei-simple/navigation";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    switch ($view)
        case "page" return
            $div/following::tei:pb[1]
        case "body" return
            ($div/following-sibling::*, $div/../following-sibling::*)[1]
        default return
            nav:get-next($config, $div)
};


declare function nav:get-next($config as map(*), $div as element()) {
    if ($div/tei:div[count(ancestor::tei:div) < $config?depth]) then
        if ($config?fill > 0 and count(($div/tei:div[1])/preceding-sibling::*//*) < $config?fill) then
            nav:get-next($config, $div/tei:div[1])
        else
            $div/tei:div[1]
    else
        $div/following::tei:div[1][count(ancestor::tei:div) < $config?depth]
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    switch ($view)
        case "page" return
            $div/preceding::tei:pb[1]
        case "body" return
            ($div/preceding-sibling::*, $div/../preceding-sibling::*)[1]
        default return
            nav:get-previous-div($config, $div)
};


declare function nav:get-previous-div($config as map(*), $div as element()) {
    let $parent := $div/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
    let $prevDiv := $div/preceding::tei:div[count(ancestor::tei:div) < $config?depth][1]
    return
        nav:get-previous-recursive(
            $config,
            if ($parent and (empty($prevDiv) or $div/.. >> $prevDiv)) then $div/.. else $prevDiv
        )
};

declare %private function nav:get-previous-recursive($config as map(*), $div as element(tei:div)?) {
    if (empty($div)) then
        ()
    else
        if (
            empty($div/preceding-sibling::tei:div)  (: first div in section :)
            and $config?fill > 0
            and count($div/preceding-sibling::*//*) < $config?fill (: less than 5 elements before div :)
            and $div/.. instance of element(tei:div) (: parent is a div :)
        ) then
            nav:get-previous-recursive($config, $div/ancestor::tei:div[count(ancestor::tei:div) < $config?depth][1])
        else
            $div
};
