(:
 :
 :  Copyright (C) 2019 Wolfgang Meier
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

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare function local:sort($facets as map(*)?) {
    array {
        if (exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            order by $key ascending
            return
                map { $key: $value }
        else
            ()
    }
};

declare function local:print-table($config as map(*), $nodes as element()+, $values as xs:string*, $params as xs:string*) {
    let $all := exists($config?max) and request:get-parameter("all-" || $config?dimension, ())
    let $count := if ($all) then 50 else $config?max
    let $facets :=
        if (exists($values)) then
            ft:facets($nodes, $config?dimension, $count, $values)
        else
            ft:facets($nodes, $config?dimension, $count)
    return
        if (map:size($facets) > 0) then
            <table>
            {
                array:for-each(local:sort($facets), function($entry) {
                    map:for-each($entry, function($label, $freq) {
                        <tr>
                            <td>
                                <paper-checkbox class="facet" name="facet-{$config?dimension}" value="{$label}">
                                    { if ($label = $params[1]) then attribute checked { "checked" } else () }
                                    {
                                        if (exists($config?output)) then
                                            $config?output($label)
                                        else
                                            $label
                                    }
                                </paper-checkbox>
                            </td>
                            <td>{$freq}</td>
                        </tr>
                    })
                }),
                if (empty($params)) then
                    ()
                else
                    let $nested := local:print-table($config, $nodes, ($values, head($params)), tail($params))
                    return
                        if ($nested) then
                            <tr class="nested">
                                <td colspan="2">
                                {$nested}
                                </td>
                            </tr>
                        else
                            ()
            }
            </table>
        else
            ()
};

declare function local:display($config as map(*), $nodes as element()+) {
    let $params := request:get-parameter("facet-" || $config?dimension, ())
    let $table := local:print-table($config, $nodes, (), $params)
    where $table
    return
        <div>
            <h3><pb-i18n key="{$config?heading}">{$config?heading}</pb-i18n>
            {
                if (exists($config?max)) then
                    <paper-checkbox class="facet" name="all-{$config?dimension}">
                        { if (request:get-parameter("all-" || $config?dimension, ())) then attribute checked { "checked" } else () }
                        <pb-i18n key="facets.show">Show top 50</pb-i18n>
                    </paper-checkbox>
                else
                    ()
            }
            </h3>
            {
                $table
            }
        </div>
};

let $hits := session:get-attribute($config:session-prefix || ".hits")
where count($hits) > 0
return
    <div>
    {
        for $config in $config:facets?*
        return
            local:display($config, $hits)
    }
    </div>
