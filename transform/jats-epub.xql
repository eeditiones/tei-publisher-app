(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/jats.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/jats/epub";

declare default element namespace "";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace pb='http://teipublisher.com/1.0';

declare namespace mml='http://www.w3.org/1998/Math/MathML';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

import module namespace epub="http://www.tei-c.org/tei-simple/xquery/functions/epub";

(: generated template function for element spec: preformat :)
declare %private function model:template-preformat($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pre>{$config?apply-children($config, $node, $params?content)}</pre></t>/*
};
(: generated template function for element spec: disp-formula :)
declare %private function model:template-disp-formula($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-formula menu="menu" display="display">
                                {$config?apply-children($config, $node, $params?content)}
                            </pb-formula></t>/*
};
(: generated template function for element spec: mml:math :)
declare %private function model:template-mml_math($config as map(*), $node as node()*, $params as map(*)) {
    <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">{$config?apply-children($config, $node, $params?content)}</math>
};
(: generated template function for element spec: ref :)
declare %private function model:template-ref($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li id="{$config?apply-children($config, $node, $params?id)}">{$config?apply-children($config, $node, $params?authors)}: {$config?apply-children($config, $node, $params?title)}. {$config?apply-children($config, $node, $params?source)}{$config?apply-children($config, $node, $params?year)}</li></t>/*
};
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
                        html:body($config, ., ("tei-body", css:map-rend-to-class(.)), .)
                    case element(sec) return
                        html:section($config, ., ("tei-sec", css:map-rend-to-class(.)), .)
                    case element(title) return
                        if (parent::caption) then
                            html:heading($config, ., ("tei-title1", css:map-rend-to-class(.)), ., 3)
                        else
                            html:heading($config, ., ("tei-title2", css:map-rend-to-class(.)), ., count(ancestor::sec) + 1)
                    case element(p) return
                        if (ancestor::fn) then
                            html:inline($config, ., ("tei-p1", css:map-rend-to-class(.)), .)
                        else
                            if (ancestor::td) then
                                epub:block($config, ., ("tei-p2", css:map-rend-to-class(.)), .)
                            else
                                html:paragraph($config, ., ("tei-p3", css:map-rend-to-class(.)), .)
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
                        epub:block($config, ., ("tei-table-wrap", css:map-rend-to-class(.)), .)
                    case element(table) return
                        html:table($config, ., ("tei-table", "table", css:map-rend-to-class(.)), .)
                    case element(tr) return
                        html:row($config, ., ("tei-tr", css:map-rend-to-class(.)), .)
                    case element(td) return
                        html:cell($config, ., ("tei-td", css:map-rend-to-class(.)), ., ())
                    case element(th) return
                        html:cell($config, ., css:get-rendition(., ("tei-th", css:map-rend-to-class(.))), ., ())
                    case element(article-meta) return
                        if ($parameters?header='short' or $parameters?mode='breadcrumbs') then
                            epub:block($config, ., ("tei-article-meta1", css:map-rend-to-class(.)), (title-group, contrib-group))
                        else
                            (
                                html:pass-through($config, ., ("tei-article-meta2", css:map-rend-to-class(.)), title-group),
                                epub:block($config, ., ("tei-article-meta3", "flex", css:map-rend-to-class(.)), (contrib-group, (pub-date[@iso-8601-date], pub-date)[1])),
                                epub:block($config, ., ("tei-article-meta4", css:map-rend-to-class(.)), abstract)
                            )

                    case element(title-group) return
                        if ($parameters?mode='breadcrumbs') then
                            html:inline($config, ., ("tei-title-group1", css:map-rend-to-class(.)), article-title/text())
                        else
                            if ($parameters?header='short') then
                                (
                                    html:link($config, ., ("tei-title-group2", css:map-rend-to-class(.)), article-title, $parameters?doc, (), map {}),
                                    epub:block($config, ., ("tei-title-group3", css:map-rend-to-class(.)), subtitle)
                                )

                            else
                                $config?apply($config, ./node())
                    case element(article-title) return
                        if ($parameters?header='short') then
                            html:heading($config, ., ("tei-article-title1", css:map-rend-to-class(.)), ., 5)
                        else
                            if (ancestor::article-meta) then
                                html:heading($config, ., ("tei-article-title2", "title", css:map-rend-to-class(.)), ., 1)
                            else
                                if (ancestor::ref-list) then
                                    html:pass-through($config, ., ("tei-article-title3", css:map-rend-to-class(.)), .)
                                else
                                    $config?apply($config, ./node())
                    case element(subtitle) return
                        html:heading($config, ., ("tei-subtitle", css:map-rend-to-class(.)), ., 5)
                    case element(caption) return
                        html:body($config, ., ("tei-caption", css:map-rend-to-class(.)), .)
                    case element(disp-quote) return
                        html:cit($config, ., ("tei-disp-quote", css:map-rend-to-class(.)), ., ())
                    case element(fn) return
                        if (label) then
                            epub:note($config, ., ("tei-fn1", css:map-rend-to-class(.)), node() except label, (), ())
                        else
                            epub:note($config, ., ("tei-fn2", css:map-rend-to-class(.)), ., (), ())
                    case element(label) return
                        epub:block($config, ., ("tei-label", css:map-rend-to-class(.)), .)
                    case element(xref) return
                        if (@ref-type='bibr') then
                            html:link($config, ., ("tei-xref1", css:map-rend-to-class(.)), ., '#' || @rid, (), map {})
                        else
                            if (@ref-type='fn') then
                                html:pass-through($config, ., ("tei-xref2", css:map-rend-to-class(.)), let $rid := @rid return root($parameters?root)//fn[@id=$rid])
                            else
                                $config?apply($config, ./node())
                    case element(contrib) return
                        if (preceding-sibling::contrib) then
                            html:inline($config, ., ("tei-contrib1", css:map-rend-to-class(.)), name)
                        else
                            html:inline($config, ., ("tei-contrib2", css:map-rend-to-class(.)), name)
                    case element(contrib-group) return
                        if ($parameters?mode='breadcrumbs') then
                            html:inline($config, ., ("tei-contrib-group1", css:map-rend-to-class(.)), contrib)
                        else
                            epub:block($config, ., ("tei-contrib-group2", css:map-rend-to-class(.)), contrib)
                    case element(code) return
                        html:webcomponent($config, ., ("tei-code", css:map-rend-to-class(.)), ., 'pb-code-highlight', map {"language": (@language, 'xml')[1], "line-numbers": false()})
                    case element(preformat) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-preformat($config, ., $params)
                        return
                                                html:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-preformat", css:map-rend-to-class(.)), $content)
                    case element(monospace) return
                        html:inline($config, ., ("tei-monospace", "code", css:map-rend-to-class(.)), .)
                    case element(ext-link) return
                        html:link($config, ., ("tei-ext-link", css:map-rend-to-class(.)), ., @xlink:href, (), map {})
                    case element(fig) return
                        if (@position='float') then
                            html:figure($config, ., ("tei-fig1", "float-right", css:map-rend-to-class(.)), (graphic, caption), ())
                        else
                            html:figure($config, ., ("tei-fig2", css:map-rend-to-class(.)), (graphic, caption), ())
                    case element(graphic) return
                        html:graphic($config, ., ("tei-graphic", css:map-rend-to-class(.)), ., @xlink:href, (), (), (), ())
                    case element(abstract) return
                        epub:block($config, ., ("tei-abstract", "abstract", css:map-rend-to-class(.)), .)
                    case element(name) return
                        html:inline($config, ., ("tei-name", css:map-rend-to-class(.)), (given-names,surname))
                    case element(surname) return
                        if (../given-names) then
                            html:inline($config, ., ("tei-surname1", css:map-rend-to-class(.)), (' ', .))
                        else
                            html:inline($config, ., ("tei-surname2", css:map-rend-to-class(.)), .)
                    case element(pub-date) return
                        epub:block($config, ., ("tei-pub-date", css:map-rend-to-class(.)), if (matches(@iso-8601-date, "^\d{4}-\d{2}$")) then   format-date(@iso-8601-date || "-01", '[MNn] [Y]', $parameters?language, (), ()) else   format-date(@iso-8601-date, '[D]. [MNn] [Y]', $parameters?language, (), ()))
                    case element(disp-formula) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-disp-formula($config, ., $params)
                        return
                                                html:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-disp-formula", css:map-rend-to-class(.)), $content)
                    case element(mml:math) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-mml_math($config, ., $params)
                        return
                                                html:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-mml_math", css:map-rend-to-class(.)), $content)
                    case element(article) return
                        html:document($config, ., ("tei-article", css:map-rend-to-class(.)), .)
                    case element(back) return
                        epub:block($config, ., ("tei-back", css:map-rend-to-class(.)), ref-list)
                    case element(ref-list) return
                        (
                            html:pass-through($config, ., ("tei-ref-list1", css:map-rend-to-class(.)), title),
                            html:list($config, ., ("tei-ref-list2", "references", css:map-rend-to-class(.)), ref, 'ordered')
                        )

                    case element(ref) return
                        let $params := 
                            map {
                                "title": .//article-title,
                                "source": if (exists(.//source)) then (" In: ",.//source, (", ")) else (),
                                "authors": let $names := for $name in  .//person-group[@person-group-type='author']/name return normalize-space($name) return string-join($names, ', '),
                                "year": .//year,
                                "id": @id,
                                "content": .
                            }

                                                let $content := 
                            model:template-ref($config, ., $params)
                        return
                                                html:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-ref", css:map-rend-to-class(.)), $content)
                    case element(journal-meta) return
                        epub:block($config, ., ("tei-journal-meta", "journal-meta", css:map-rend-to-class(.)), (.//journal-title, publisher, issn))
                    case element(journal-title) return
                        html:inline($config, ., ("tei-journal-title", "journal-title", css:map-rend-to-class(.)), .)
                    case element(journal-title-group) return
                        html:inline($config, ., ("tei-journal-title-group", "journal-title-group", css:map-rend-to-class(.)), .)
                    case element(publisher) return
                        html:inline($config, ., ("tei-publisher", "publisher", css:map-rend-to-class(.)), .)
                    case element(issn) return
                        html:inline($config, ., ("tei-issn", "issn", css:map-rend-to-class(.)), .)
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

