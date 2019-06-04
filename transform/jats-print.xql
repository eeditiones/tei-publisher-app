(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/jats.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/jats/fo";

declare default element namespace "";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace fo="http://www.tei-c.org/tei-simple/xquery/functions/fo";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["fo","print"],
                "odd": "/db/apps/tei-publisher/odd/jats.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    let $config := fo:init($config, $input)
    
    return (
        
        let $output := model:apply($config, $input)
        return
            $output
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
                        fo:body($config, ., ("tei-body"), .)
                    case element(sec) return
                        fo:section($config, ., ("tei-sec"), .)
                    case element(title) return
                        fo:heading($config, ., ("tei-title"), ., count(ancestor::sec))
                    case element(p) return
                        fo:paragraph($config, ., ("tei-p"), .)
                    case element(list) return
                        fo:list($config, ., ("tei-list"), ., if (@list-type = 'order') then 'ordered' else ())
                    case element(list-item) return
                        fo:listItem($config, ., ("tei-list-item"), ., ())
                    case element(uri) return
                        fo:link($config, ., ("tei-uri"), ., @xlink:href, map {})
                    case element(bold) return
                        fo:inline($config, ., ("tei-bold"), .)
                    case element(italic) return
                        fo:inline($config, ., ("tei-italic"), .)
                    case element(table-wrap) return
                        fo:block($config, ., ("tei-table-wrap"), .)
                    case element(table) return
                        fo:table($config, ., ("tei-table", "table"), .)
                    case element(tr) return
                        fo:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        fo:cell($config, ., ("tei-td"), ., ())
                    case element(th) return
                        fo:cell($config, ., css:get-rendition(., ("tei-th")), ., ())
                    case element(article-meta) return
                        fo:block($config, ., ("tei-article-meta"), title-group)
                    case element(title-group) return
                        (
                            fo:link($config, ., ("tei-title-group1"), article-title, $parameters?doc, map {}),
                            fo:block($config, ., ("tei-title-group2"), subtitle)
                        )

                    case element(article-title) return
                        if ($parameters?header='short') then
                            fo:heading($config, ., ("tei-article-title"), ., 5)
                        else
                            $config?apply($config, ./node())
                    case element(subtitle) return
                        fo:heading($config, ., ("tei-subtitle"), ., 6)
                    case element() return
                        if (namespace-uri(.) = '') then
                            $config?apply($config, ./node())
                        else
                            .
                    case text() | xs:anyAtomicType return
                        fo:escapeChars(.)
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
                    fo:escapeChars(.)
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

