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

module namespace tpu="http://www.tei-c.org/tei-publisher/util";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare function tpu:parse-pi($doc as document-node(), $view as xs:string?) {
    let $default := map {
        "view": ($view, $config:default-view)[1],
        "odd": $config:odd,
        "depth": $config:pagination-depth,
        "fill": $config:pagination-fill
    }
    let $pis :=
        map:new(
            for $pi in $doc/processing-instruction("teipublisher")
            let $analyzed := analyze-string($pi, '([^\s]+)\s*=\s*"(.*?)"')
            for $match in $analyzed/fn:match
            return
                map:entry($match/fn:group[@nr="1"], $match/fn:group[@nr="2"])
        )
    return
        map:new(($default, $pis))
};
