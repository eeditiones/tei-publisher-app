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
    let $count := if ($all) then () else $config?max
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
    <div>
        <h3>{$config?heading}
        {
            if (exists($config?max)) then
                <paper-checkbox class="facet" name="all-{$config?dimension}">
                    { if (request:get-parameter("all-" || $config?dimension, ())) then attribute checked { "checked" } else () }
                    Show all
                </paper-checkbox>
            else
                ()
        }
        </h3>
        {
            let $params := request:get-parameter("facet-" || $config?dimension, ())
            return
                local:print-table($config, $nodes, (), $params)
        }
    </div>
};

let $hits := session:get-attribute("apps.simple")
where count($hits) > 0
return
    <div>
    {
        for $config in $config:facets?*
        return
            local:display($config, $hits)
    }
    </div>
