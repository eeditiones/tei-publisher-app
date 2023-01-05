(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/jats.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/jats/web";

declare default element namespace "";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace pb='http://teipublisher.com/1.0';

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
        let $mode := 
        if (exists($config?mode)) then $config?mode else ()
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
                        html:body($config, ., ("tei-body", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(sec) return
                        html:section($config, ., ("tei-sec", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(title) return
                        if (parent::caption) then
                            html:heading($config, ., ("tei-title1", css:map-rend-to-class(.)), ., 3)                            => model:map($node, $trackIds)
                        else
                            html:heading($config, ., ("tei-title2", css:map-rend-to-class(.)), ., count(ancestor::sec))                            => model:map($node, $trackIds)
                    case element(p) return
                        if (ancestor::td) then
                            html:block($config, ., ("tei-p1", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                        else
                            html:paragraph($config, ., ("tei-p2", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                    case element(list) return
                        html:list($config, ., ("tei-list", css:map-rend-to-class(.)), ., if (@list-type = 'order') then 'ordered' else ())                        => model:map($node, $trackIds)
                    case element(list-item) return
                        html:listItem($config, ., ("tei-list-item", css:map-rend-to-class(.)), ., ())                        => model:map($node, $trackIds)
                    case element(uri) return
                        html:link($config, ., ("tei-uri", css:map-rend-to-class(.)), ., @xlink:href, (), map {})                        => model:map($node, $trackIds)
                    case element(bold) return
                        html:inline($config, ., ("tei-bold", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(italic) return
                        html:inline($config, ., ("tei-italic", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(table-wrap) return
                        html:block($config, ., ("tei-table-wrap", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(table) return
                        html:table($config, ., ("tei-table", "table", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(tr) return
                        html:row($config, ., ("tei-tr", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(td) return
                        html:cell($config, ., ("tei-td", css:map-rend-to-class(.)), ., ())                        => model:map($node, $trackIds)
                    case element(th) return
                        html:cell($config, ., css:get-rendition(., ("tei-th", css:map-rend-to-class(.))), ., ())                        => model:map($node, $trackIds)
                    case element(article-meta) return
                        if ($parameters?header='short') then
                            html:block($config, ., ("tei-article-meta1", css:map-rend-to-class(.)), (title-group, contrib-group))                            => model:map($node, $trackIds)
                        else
                            html:block($config, ., ("tei-article-meta2", css:map-rend-to-class(.)), title-group)                            => model:map($node, $trackIds)
                    case element(title-group) return
                        (
                            html:link($config, ., ("tei-title-group1", css:map-rend-to-class(.)), article-title, $parameters?doc, (), map {})                            => model:map($node, $trackIds),
                            html:block($config, ., ("tei-title-group2", css:map-rend-to-class(.)), subtitle)                            => model:map($node, $trackIds)
                        )

                    case element(article-title) return
                        if ($parameters?header='short') then
                            html:heading($config, ., ("tei-article-title", css:map-rend-to-class(.)), ., 5)                            => model:map($node, $trackIds)
                        else
                            $config?apply($config, ./node())
                    case element(subtitle) return
                        html:heading($config, ., ("tei-subtitle", css:map-rend-to-class(.)), ., 5)                        => model:map($node, $trackIds)
                    case element(caption) return
                        html:body($config, ., ("tei-caption", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(disp-quote) return
                        html:cit($config, ., ("tei-disp-quote", css:map-rend-to-class(.)), ., ())                        => model:map($node, $trackIds)
                    case element(fn) return
                        html:pass-through($config, ., ("tei-fn", css:map-rend-to-class(.)), p)                        => model:map($node, $trackIds)
                    case element(label) return
                        html:block($config, ., ("tei-label", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(xref) return
                        if (@ref-type='fn') then
                            html:note($config, ., ("tei-xref", css:map-rend-to-class(.)), let $rid := @rid return root($parameters?root)//fn[@id=$rid], (), ())                            => model:map($node, $trackIds)
                        else
                            $config?apply($config, ./node())
                    case element(contrib) return
                        html:inline($config, ., ("tei-contrib", css:map-rend-to-class(.)), string-join((name/given-names, name/surname), ' '))                        => model:map($node, $trackIds)
                    case element(contrib-group) return
                        html:inline($config, ., ("tei-contrib-group", css:map-rend-to-class(.)), string-join(contrib, ', '))                        => model:map($node, $trackIds)
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

