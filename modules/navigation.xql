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

import module namespace tei-nav="http://www.tei-c.org/tei-simple/navigation/tei" at "navigation-tei.xql";
import module namespace jats-nav="http://www.tei-c.org/tei-simple/navigation/jats" at "navigation-jats.xql";

declare function nav:get-header($node as element()) {
    tei-nav:get-header($node),
    jats-nav:get-header($node)
};

declare function nav:get-section-for-node($config as map(*), $node as element()) {
    tei-nav:get-section-for-node($config, $node),
    jats-nav:get-section-for-node($config, $node)
};

declare function nav:get-section($doc) {
    tei-nav:get-section($doc),
    jats-nav:get-section($doc)
};

declare function nav:get-document-title($root as element()) {
    tei-nav:get-document-title($root),
    jats-nav:get-document-title($root)
};

declare function nav:get-content($config as map(*), $div as element()) {
    switch (namespace-uri($div))
        case "http://www.tei-c.org/ns/1.0" return
            tei-nav:get-content($config, $div)
        default return
            jats-nav:get-content($config, $div)
};

declare function nav:get-next($config as map(*), $div as element(), $view as xs:string) {
    tei-nav:get-next($config, $div, $view),
    jats-nav:get-next($config, $div, $view)
};

declare function nav:get-previous($config as map(*), $div as element(), $view as xs:string) {
    tei-nav:get-previous($config, $div, $view),
    jats-nav:get-previous($config, $div, $view)
};

declare function nav:get-previous-div($config as map(*), $div as element()) {
    tei-nav:get-previous-div($config, $div),
    jats-nav:get-previous-div($config, $div)
};

declare function nav:output-footnotes($footnotes as element()*) {
    <div class="footnotes">
        <ol>
        {
            for $note in $footnotes
            order by number($note/@value)
            return
                $note
        }
        </ol>
    </div>
};