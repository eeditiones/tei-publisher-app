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
import module namespace templates="http://exist-db.org/xquery/html-templating";

declare variable $tpu:template-config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
};

declare function tpu:parse-pi($doc as document-node(), $view as xs:string?) {
    tpu:parse-pi($doc, $view, request:get-parameter("odd", ()))
};

declare function tpu:parse-pi($doc as document-node(), $view as xs:string?, $odd as xs:string?) {
    let $defaultConfig := config:default-config(document-uri($doc))
    let $default := map {
        "view": ($view, $defaultConfig?view)[1],
        "depth": $defaultConfig?depth,
        "fill": $defaultConfig?fill,
        "type": config:document-type($doc/*),
        "template": $defaultConfig?template
    }
    let $pis :=
        map:merge(
            for $pi in $doc/processing-instruction("teipublisher")
            let $analyzed := analyze-string($pi, '([^\s]+)\s*=\s*"(.*?)"')
            for $match in $analyzed/fn:match
            let $key := $match/fn:group[@nr="1"]/string()
            let $value := $match/fn:group[@nr="2"]/string()
            return
                if ($key = "view" and $value != $view) then
                    ()
                else if ($key = ('depth', 'fill')) then
                    map:entry($key, number($value))
                else
                    map:entry($key, $value)
        )
    (: Check if ODD configured in PI is available :)
    let $cfgOddAvail :=
        if ($pis?odd) then
            doc-available($config:odd-root || "/" || $pis?odd)
        else
            false()
    let $pisWithOdd :=
        if ($defaultConfig?overwrite) then
            if ($cfgOddAvail) then
                map:merge(($default, map { "odd": $pis?odd, "output": $pis?output }))
            else
                map:merge(($default, map { "output": $pis?output }))
        else
            $pis
    (: ODD from parameter should overwrite ODD defined in PI :)
    let $config :=
        if ($odd) then
            map:merge(($pisWithOdd, map { "odd": $odd }))
        else if ($cfgOddAvail) then
            $pisWithOdd
        else
            map:merge(($pisWithOdd, map { "odd": $defaultConfig?odd }))
    return
        map:merge(($default, $config))
};

declare function tpu:get-template-config($request as map(*)) {
    map:merge((
        $tpu:template-config,
        map {
            $templates:CONFIG_PARAM_RESOLVER : function($param) {
                let $pval := array:fold-right(
                    [
                        request:get-parameter($param, ()),
                        $request?parameters($param),
                        request:get-attribute($param),
                        session:get-attribute($config:session-prefix || "." || $param)
                    ], (),
                    function($zero, $current) {
                        if (exists($zero)) then
                            $zero
                        else
                            $current
                    }
                )
                return
                    $pval
            }
        }))
};