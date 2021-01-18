(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/jats.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/jats/web";

declare default element namespace "";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["web"],
                "odd": "/db/apps/tei-publisher/odd/jats.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    
    return (
        html:prepare($config, $input),
    
        let $output := model:apply($config, $input)
        return
            html:finish($config, $output)
    )
};

declare function model:apply($config as map(*), $input as node()*) {
        let $parameters := 
        if (exists($config?parameters)) then $config?parameters else map {}
        let $get := 
        model:source($parameters, ?)
    return
    $input !         (
            let $node := 
                .
            return
                            typeswitch(.)
                    case element(body) return
                        html:body($config, ., ("tei-body", css:map-rend-to-class(.)), .)
                    case element(sec) return
                        html:section($config, ., ("tei-sec", css:map-rend-to-class(.)), .)
                    case element(title) return
                        html:heading($config, ., ("tei-title", css:map-rend-to-class(.)), ., count(ancestor::sec))
                    case element(p) return
                        html:paragraph($config, ., ("tei-p", css:map-rend-to-class(.)), .)
                    case element(list) return
                        html:list($config, ., ("tei-list", css:map-rend-to-class(.)), ., if (@list-type = 'order') then 'ordered' else ())
                    case element(list-item) return
                        html:listItem($config, ., ("tei-list-item", css:map-rend-to-class(.)), ., ())
                    case element(uri) return
                        html:link($config, ., ("tei-uri", css:map-rend-to-class(.)), ., @xlink:href, (), map {})
                    case element(bold) return
                        html:inline($config, ., ("tei-bold", css:map-rend-to-class(.)), .)
                    case element(italic) return
                        html:inline($config, ., ("tei-italic", css:map-rend-to-class(.)), .)
                    case element(table-wrap) return
                        html:block($config, ., ("tei-table-wrap", css:map-rend-to-class(.)), .)
                    case element(table) return
                        html:table($config, ., ("tei-table", "table", css:map-rend-to-class(.)), .)
                    case element(tr) return
                        html:row($config, ., ("tei-tr", css:map-rend-to-class(.)), .)
                    case element(td) return
                        html:cell($config, ., ("tei-td", css:map-rend-to-class(.)), ., ())
                    case element(th) return
                        html:cell($config, ., css:get-rendition(., ("tei-th", css:map-rend-to-class(.))), ., ())
                    case element(article-meta) return
                        html:block($config, ., ("tei-article-meta", css:map-rend-to-class(.)), title-group)
                    case element(title-group) return
                        (
                            html:link($config, ., ("tei-title-group1", css:map-rend-to-class(.)), article-title, $parameters?doc, (), map {}),
                            html:block($config, ., ("tei-title-group2", css:map-rend-to-class(.)), subtitle)
                        )

                    case element(article-title) return
                        if ($parameters?header='short') then
                            html:heading($config, ., ("tei-article-title", css:map-rend-to-class(.)), ., 5)
                        else
                            $config?apply($config, ./node())
                    case element(subtitle) return
                        html:heading($config, ., ("tei-subtitle", css:map-rend-to-class(.)), ., 6)
                    case element(exist:match) return
                        html:match($config, ., .)
                    case element() return
                        if (namespace-uri(.) = '') then
                            $config?apply($config, ./node())
                        else
                            .
                    case text() | xs:anyAtomicType return
                        html:escapeChars(.)
                    default return 
                        $config?apply($config, ./node())

        )

};

declare function model:apply-children($config as map(*), $node as element(), $content as item()*) {
        
    if ($config?template) then
        $content
    else
        $content ! (
            typeswitch(.)
                case element() return
                    if (. is $node) then
                        $config?apply($config, ./node())
                    else
                        $config?apply($config, .)
                default return
                    html:escapeChars(.)
        )
};

declare function model:source($parameters as map(*), $elem as element()) {
        
    let $id := $elem/@exist:id
    return
        if ($id and $parameters?root) then
            util:node-by-id($parameters?root, $id)
        else
            $elem
};

