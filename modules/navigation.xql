(:
 :
 :  Copyright (C) 2017 TEI Publisher Project
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

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace tei-nav="http://www.tei-c.org/tei-simple/navigation/tei" at "navigation-tei.xql";
import module namespace jats-nav="http://www.tei-c.org/tei-simple/navigation/jats" at "navigation-jats.xql";
import module namespace docbook-nav="http://www.tei-c.org/tei-simple/navigation/docbook" at "navigation-dbk.xql";

declare %private function nav:dispatch($config as map(*), $function as xs:string, $args as array(*)) {
    let $fn := function-lookup(xs:QName($config?type || "-nav:" || $function), array:size($args))
    return
        if (exists($fn)) then
            apply($fn, $args)
        else
            ()
};

declare function nav:get-root($root as xs:string?, $options as map(*)?) {
    tei-nav:get-root($root, $options),
    docbook-nav:get-root($root, $options)
};

declare function nav:get-header($config as map(*), $node as element()) {
    nav:dispatch($config, "get-header", [$config, $node])
};

declare function nav:get-section-for-node($config as map(*), $node as element()) {
    nav:dispatch($config, "get-section-for-node", [$config, $node])
};

declare function nav:get-section($config as map(*), $doc as node()) {
    nav:dispatch($config, "get-section", [$config, $doc])
};

declare function nav:get-metadata($root as element(), $field as xs:string) {
    nav:get-metadata(map { "type": config:document-type($root) }, $root, $field)
};

declare function nav:get-metadata($config as map(*), $root as element(), $field as xs:string) {
    nav:dispatch($config, "get-metadata", [$config, $root, $field])
};

declare function nav:get-document-title($config as map(*), $root as element()) {
    nav:dispatch($config, "get-document-title", [$config, $root])
};

declare function nav:get-subsections($config as map(*), $root as node()) {
    nav:dispatch($config, "get-subsections", [$config, $root])
};

declare function nav:get-section-heading($config as map(*), $section as node()) {
    nav:dispatch($config, "get-section-heading", [$config, $section])
};

declare function nav:get-first-page-start($config as map(*), $data as node()) {
    nav:dispatch($config, "get-first-page-start", [$config, $data])
};

declare function nav:sort($sortBy as xs:string, $items as element()*) {
    if (empty($items)) then
        ()
    else
        nav:dispatch(map { "type": config:document-type(head($items)) }, "sort", [$sortBy, $items])
};

declare function nav:get-content($config as map(*), $div as element()) {
    nav:dispatch($config, "get-content", [$config, $div])
};

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    nav:dispatch($config, "get-next", [$config, $div, $view])
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    nav:dispatch($config, "get-previous", [$config, $div, $view])
};

declare function nav:filler($config as map(*), $div as element()?) {
    nav:dispatch($config, "filler", [$config, $div])
};

declare function nav:is-filler($config as map(*), $div) {
    nav:dispatch($config, "is-filler", [$config, $div])
};

declare function nav:output-footnotes($footnotes as element()*) {
    <div class="popovers">
    {
        $footnotes/self::pb-popover
    }
    </div>,
    <div class="footnotes">
    {
        $footnotes[not(self::pb-popover)]
    }
    </div>
};