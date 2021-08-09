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
        let $trackIds := 
        $parameters?track-ids
        let $get := 
        model:source($parameters, ?)
    return
    $input !         (
            let $node := 
                .
            return
                            typeswitch(.)
                    case element(body) return
                        fo:body($config, ., ("tei-body", css:map-rend-to-class(.)), .)
                    case element(sec) return
                        fo:section($config, ., ("tei-sec", css:map-rend-to-class(.)), .)
                    case element(title) return
                        fo:heading($config, ., ("tei-title", css:map-rend-to-class(.)), ., count(ancestor::sec))
                    case element(p) return
                        fo:paragraph($config, ., ("tei-p", css:map-rend-to-class(.)), .)
                    case element(list) return
                        fo:list($config, ., ("tei-list", css:map-rend-to-class(.)), ., if (@list-type = 'order') then 'ordered' else ())
                    case element(list-item) return
                        fo:listItem($config, ., ("tei-list-item", css:map-rend-to-class(.)), ., ())
                    case element(uri) return
                        fo:link($config, ., ("tei-uri", css:map-rend-to-class(.)), ., @xlink:href, map {})
                    case element(bold) return
                        fo:inline($config, ., ("tei-bold", css:map-rend-to-class(.)), .)
                    case element(italic) return
                        fo:inline($config, ., ("tei-italic", css:map-rend-to-class(.)), .)
                    case element(table-wrap) return
                        fo:block($config, ., ("tei-table-wrap", css:map-rend-to-class(.)), .)
                    case element(table) return
                        fo:table($config, ., ("tei-table", "table", css:map-rend-to-class(.)), .)
                    case element(tr) return
                        fo:row($config, ., ("tei-tr", css:map-rend-to-class(.)), .)
                    case element(td) return
                        fo:cell($config, ., ("tei-td", css:map-rend-to-class(.)), ., ())
                    case element(th) return
                        fo:cell($config, ., css:get-rendition(., ("tei-th", css:map-rend-to-class(.))), ., ())
                    case element(article-meta) return
                        fo:block($config, ., ("tei-article-meta", css:map-rend-to-class(.)), title-group)
                    case element(title-group) return
                        (
                            fo:link($config, ., ("tei-title-group1", css:map-rend-to-class(.)), article-title, $parameters?doc, map {}),
                            fo:block($config, ., ("tei-title-group2", css:map-rend-to-class(.)), subtitle)
                        )

                    case element(article-title) return
                        if ($parameters?header='short') then
                            fo:heading($config, ., ("tei-article-title", css:map-rend-to-class(.)), ., 5)
                        else
                            $config?apply($config, ./node())
                    case element(subtitle) return
                        fo:heading($config, ., ("tei-subtitle", css:map-rend-to-class(.)), ., 6)
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

declare function model:process-annotation($html, $context as node()) {
        
    let $classRegex := analyze-string($html/@class, '\s?annotation-([^\s]+)\s?')
    return
        if ($classRegex//fn:match) then (
            if ($html/@data-type) then
                ()
            else
                attribute data-type { ($classRegex//fn:group)[1]/string() },
            if ($html/@data-annotation) then
                ()
            else
                attribute data-annotation {
                    map:merge($context/@* ! map:entry(node-name(.), ./string()))
                    => serialize(map { "method": "json" })
                }
        ) else
            ()
                    
};

declare function model:map($html, $context as node(), $trackIds as item()?) {
        
    if ($trackIds) then
        for $node in $html
        return
            typeswitch ($node)
                case document-node() | comment() | processing-instruction() return 
                    $node
                case element() return
                    if ($node/@class = ("footnote")) then
                        if (local-name($node) = 'pb-popover') then
                            ()
                        else
                            element { node-name($node) }{
                                $node/@*,
                                $node/*[@class="fn-number"],
                                model:map($node/*[@class="fn-content"], $context, $trackIds)
                            }
                    else
                        element { node-name($node) }{
                            attribute data-tei { util:node-id($context) },
                            $node/@*,
                            model:process-annotation($node, $context),
                            $node/node()
                        }
                default return
                    <pb-anchor data-tei="{ util:node-id($context) }">{$node}</pb-anchor>
    else
        $html
                    
};

