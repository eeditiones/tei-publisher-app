(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/jats.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/jats/epub";

declare default element namespace "";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

import module namespace epub="http://www.tei-c.org/tei-simple/xquery/functions/epub";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["epub","web"],
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
                        html:body($config, ., ("tei-body"), .)
                    case element(sec) return
                        html:section($config, ., ("tei-sec"), .)
                    case element(title) return
                        html:heading($config, ., ("tei-title"), ., count(ancestor::sec))
                    case element(p) return
                        html:paragraph($config, ., ("tei-p"), .)
                    case element(list) return
                        html:list($config, ., ("tei-list"), ., if (@list-type = 'order') then 'ordered' else ())
                    case element(list-item) return
                        html:listItem($config, ., ("tei-list-item"), ., ())
                    case element(uri) return
                        html:link($config, ., ("tei-uri"), ., @xlink:href, (), map {})
                    case element(bold) return
                        html:inline($config, ., ("tei-bold"), .)
                    case element(italic) return
                        html:inline($config, ., ("tei-italic"), .)
                    case element(table-wrap) return
                        epub:block($config, ., ("tei-table-wrap"), .)
                    case element(table) return
                        html:table($config, ., ("tei-table", "table"), .)
                    case element(tr) return
                        html:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        html:cell($config, ., ("tei-td"), ., ())
                    case element(th) return
                        html:cell($config, ., css:get-rendition(., ("tei-th")), ., ())
                    case element(article-meta) return
                        epub:block($config, ., ("tei-article-meta"), title-group)
                    case element(title-group) return
                        (
                            html:link($config, ., ("tei-title-group1"), article-title, $parameters?doc, (), map {}),
                            epub:block($config, ., ("tei-title-group2"), subtitle)
                        )

                    case element(article-title) return
                        if ($parameters?header='short') then
                            html:heading($config, ., ("tei-article-title"), ., 5)
                        else
                            $config?apply($config, ./node())
                    case element(subtitle) return
                        html:heading($config, ., ("tei-subtitle"), ., 6)
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

