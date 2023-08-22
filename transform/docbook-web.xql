(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/web";

declare default element namespace "http://docbook.org/ns/docbook";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace pb='http://teipublisher.com/1.0';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

(: Generated behaviour function for ident definitionList :)
declare %private function model:definitionList($config as map(*), $node as node()*, $class as xs:string+, $content) {
    $node ! (

        
        <t xmlns=""><dl>{$config?apply-children($config, $node, $content)}</dl></t>/*
    )
};

(: Generated behaviour function for ident definition :)
declare %private function model:definition($config as map(*), $node as node()*, $class as xs:string+, $content, $term) {
    $node ! (

        
        <t xmlns=""><dt>{$config?apply-children($config, $node, $term)}</dt><dd>{$config?apply-children($config, $node, $content)}</dd></t>/*
    )
};

(: Generated behaviour function for ident iframe :)
declare %private function model:iframe($config as map(*), $node as node()*, $class as xs:string+, $content, $src, $width, $height) {
    $node ! (

        
        <t xmlns=""><iframe src="{$config?apply-children($config, $node, $src)}" width="{$config?apply-children($config, $node, $width)}" height="{$config?apply-children($config, $node, $height)}" frameborder="0" gesture="media" allow="encrypted-media" allowfullscreen="allowfullscreen"/></t>/*
    )
};

(: generated template function for element spec: title :)
declare %private function model:template-title2($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><h1>
                                <pb-link path="{$config?apply-children($config, $node, $params?path)}" emit="transcription">{$config?apply-children($config, $node, $params?content)}</pb-link>
                            </h1></t>/*
};
(: generated template function for element spec: section :)
declare %private function model:template-section4($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-observable data="{$config?apply-children($config, $node, $params?root)},{$config?apply-children($config, $node, $params?nodeId)}" emit="transcription">{$config?apply-children($config, $node, $params?content)}</pb-observable></t>/*
};
(: generated template function for element spec: link :)
declare %private function model:template-link2($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-edit-xml path="/db/apps/tei-publisher/{$config?apply-children($config, $node, $params?path)}">
                                {$config?apply-children($config, $node, $params?content)}
                                <iron-icon icon="icons:open-in-new"/>
                            </pb-edit-xml></t>/*
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["web"],
                "odd": "/db/apps/tei-publisher/odd/docbook.odd",
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
                    case element(article) return
                        if ($parameters?mode='summary') then
                            html:block($config, ., ("tei-article2", css:map-rend-to-class(.)), info)                            => model:map($node, $trackIds)
                        else
                            html:document($config, ., ("tei-article3", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                    case element(info) return
                        if (not(parent::article or parent::book)) then
                            html:block($config, ., ("tei-info3", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                        else
                            if ($parameters?header='short') then
                                (
                                    html:heading($config, ., ("tei-info5", css:map-rend-to-class(.)), title, 5)                                    => model:map($node, $trackIds),
                                    if (author) then
                                        html:block($config, ., ("tei-info6", css:map-rend-to-class(.)), author)                                        => model:map($node, $trackIds)
                                    else
                                        ()
                                )

                            else
                                html:block($config, ., ("tei-info7", css:map-rend-to-class(.)), (title, if ($parameters?skipAuthors) then () else author, pubdate, abstract))                                => model:map($node, $trackIds)
                    case element(author) return
                        if (preceding-sibling::author and not($parameters?skipAuthors)) then
                            html:inline($config, ., ("tei-author3", css:map-rend-to-class(.)), (', ', personname, affiliation))                            => model:map($node, $trackIds)
                        else
                            if (not($parameters?skipAuthors)) then
                                html:inline($config, ., ("tei-author4", css:map-rend-to-class(.)), (personname, affiliation))                                => model:map($node, $trackIds)
                            else
                                $config?apply($config, ./node())
                    case element(personname) return
                        html:inline($config, ., ("tei-personname", css:map-rend-to-class(.)), (firstname, ' ', surname))                        => model:map($node, $trackIds)
                    case element(affiliation) return
                        html:inline($config, ., ("tei-affiliation", css:map-rend-to-class(.)), (', ', .))                        => model:map($node, $trackIds)
                    case element(title) return
                        if ($parameters?mode='summary') then
                            let $params := 
                                map {
                                    "content": node(),
                                    "path": $parameters?path
                                }

                                                        let $content := 
                                model:template-title2($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-title2", "articletitle", css:map-rend-to-class(.)), $content)                            => model:map($node, $trackIds)
                        else
                            if ($parameters?mode='breadcrumbs') then
                                html:inline($config, ., ("tei-title3", css:map-rend-to-class(.)), .)                                => model:map($node, $trackIds)
                            else
                                if (parent::note) then
                                    html:heading($config, ., ("tei-title4", css:map-rend-to-class(.)), ., 4)                                    => model:map($node, $trackIds)
                                else
                                    if (parent::info and $parameters?header='short') then
                                        html:link($config, ., ("tei-title5", css:map-rend-to-class(.)), ., $parameters?doc, (), map {})                                        => model:map($node, $trackIds)
                                    else
                                        if (parent::info) then
                                            html:heading($config, ., ("tei-title6", "doc-title", css:map-rend-to-class(.)), ., ())                                            => model:map($node, $trackIds)
                                        else
                                            html:heading($config, ., ("tei-title7", "title", css:map-rend-to-class(.)), ., if ($parameters?view='single') then count(ancestor::section) + 1 else count($get(.)/ancestor::section))                                            => model:map($node, $trackIds)
                    case element(section) return
                        if ($parameters?mode='breadcrumbs') then
                            (
                                html:inline($config, ., ("tei-section1", css:map-rend-to-class(.)), $get(.)/ancestor::section/title)                                => model:map($node, $trackIds),
                                html:inline($config, ., ("tei-section2", css:map-rend-to-class(.)), title)                                => model:map($node, $trackIds)
                            )

                        else
                            (: More than one model without predicate found for ident section. Choosing first one. :)
                            let $params := 
                                map {
                                    "root": util:node-id($parameters?root),
                                    "nodeId": util:node-id($get(.)),
                                    "content": .
                                }

                                                        let $content := 
                                model:template-section4($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-section4", css:map-rend-to-class(.)), $content)                            => model:map($node, $trackIds)
                    case element(para) return
                        html:paragraph($config, ., ("tei-para", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(emphasis) return
                        if (@role='bold') then
                            html:inline($config, ., ("tei-emphasis1", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                        else
                            html:inline($config, ., ("tei-emphasis2", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                    case element(code) return
                        html:inline($config, ., ("tei-code2", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(figure) return
                        if (title|info/title) then
                            html:figure($config, ., ("tei-figure2", "figure", css:map-rend-to-class(.)), *[not(self::title|self::info)], title/node()|info/title/node())                            => model:map($node, $trackIds)
                        else
                            html:figure($config, ., ("tei-figure3", css:map-rend-to-class(.)), ., ())                            => model:map($node, $trackIds)
                    case element(informalfigure) return
                        if (caption) then
                            html:figure($config, ., ("tei-informalfigure1", "figure", css:map-rend-to-class(.)), *[not(self::caption)], caption/node())                            => model:map($node, $trackIds)
                        else
                            html:figure($config, ., ("tei-informalfigure2", "figure", css:map-rend-to-class(.)), ., ())                            => model:map($node, $trackIds)
                    case element(imagedata) return
                        html:graphic($config, ., ("tei-imagedata2", css:map-rend-to-class(.)), ., @fileref, @width, (), (), ())                        => model:map($node, $trackIds)
                    case element(itemizedlist) return
                        html:list($config, ., ("tei-itemizedlist", css:map-rend-to-class(.)), listitem, ())                        => model:map($node, $trackIds)
                    case element(listitem) return
                        html:listItem($config, ., ("tei-listitem", css:map-rend-to-class(.)), ., ())                        => model:map($node, $trackIds)
                    case element(orderedlist) return
                        html:list($config, ., ("tei-orderedlist", css:map-rend-to-class(.)), listitem, 'ordered')                        => model:map($node, $trackIds)
                    case element(procedure) return
                        html:list($config, ., ("tei-procedure", css:map-rend-to-class(.)), step, 'ordered')                        => model:map($node, $trackIds)
                    case element(step) return
                        html:listItem($config, ., ("tei-step", css:map-rend-to-class(.)), ., ())                        => model:map($node, $trackIds)
                    case element(variablelist) return
                        model:definitionList($config, ., ("tei-variablelist", css:map-rend-to-class(.)), varlistentry)                        => model:map($node, $trackIds)
                    case element(varlistentry) return
                        model:definition($config, ., ("tei-varlistentry", css:map-rend-to-class(.)), listitem/node(), term/node())                        => model:map($node, $trackIds)
                    case element(table) return
                        if (title) then
                            (
                                html:heading($config, ., ("tei-table1", css:map-rend-to-class(.)), title, ())                                => model:map($node, $trackIds),
                                html:table($config, ., ("tei-table2", css:map-rend-to-class(.)), .//tr)                                => model:map($node, $trackIds)
                            )

                        else
                            html:table($config, ., ("tei-table3", "table", css:map-rend-to-class(.)), .//tr)                            => model:map($node, $trackIds)
                    case element(informaltable) return
                        html:table($config, ., ("tei-informaltable", "table", css:map-rend-to-class(.)), .//tr)                        => model:map($node, $trackIds)
                    case element(tr) return
                        html:row($config, ., ("tei-tr", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(td) return
                        if (parent::tr/parent::thead) then
                            html:cell($config, ., ("tei-td1", css:map-rend-to-class(.)), ., ())                            => model:map($node, $trackIds)
                        else
                            html:cell($config, ., ("tei-td2", css:map-rend-to-class(.)), ., ())                            => model:map($node, $trackIds)
                    case element(programlisting) return
                        if (@role='codepen') then
                            html:webcomponent($config, ., ("tei-programlisting3", css:map-rend-to-class(.)), ., 'pb-codepen', map {"hash": substring-after(@xlink:href, '#'), "user": substring-before(@xlink:href, '#'), "theme": 'dark', "height": 480, "editable": true()})                            => model:map($node, $trackIds)
                        else
                            if (parent::cell|parent::para|parent::ab) then
                                html:inline($config, ., ("tei-programlisting4", "code", css:map-rend-to-class(.)), .)                                => model:map($node, $trackIds)
                            else
                                html:webcomponent($config, ., ("tei-programlisting5", css:map-rend-to-class(.)), text(), 'pb-code-highlight', map {"language": (@language, 'xml')[1], "line-numbers": false()})                                => model:map($node, $trackIds)
                    case element(synopsis) return
                        html:webcomponent($config, ., ("tei-synopsis4", css:map-rend-to-class(.)), text(), 'pb-code-highlight', map {"language": @language})                        => model:map($node, $trackIds)
                    case element(example) return
                        html:figure($config, ., ("tei-example", css:map-rend-to-class(.)), *[not(self::title|self::info)], info/title/node()|title/node())                        => model:map($node, $trackIds)
                    case element(function) return
                        html:inline($config, ., ("tei-function", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(command) return
                        html:inline($config, ., ("tei-command", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(parameter) return
                        html:inline($config, ., ("tei-parameter", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(filename) return
                        html:inline($config, ., ("tei-filename", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(note) return
                        html:block($config, ., ("tei-note3", "note", css:map-rend-to-class(.)), (title, *[not(self::title)]))                        => model:map($node, $trackIds)
                    case element(tag) return
                        html:inline($config, ., ("tei-tag", "code", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(link) return
                        if (@role='source') then
                            let $params := 
                                map {
                                    "path": @xlink:href,
                                    "content": .
                                }

                                                        let $content := 
                                model:template-link2($config, ., $params)
                            return
                                                        html:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-link2", css:map-rend-to-class(.)), $content)                            => model:map($node, $trackIds)
                        else
                            if (@linkend) then
                                html:webcomponent($config, ., ("tei-link3", css:map-rend-to-class(.)), ., 'pb-link', map {"uri": concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend), "xml-id": @linkend, "emit": 'transcription'})                                => model:map($node, $trackIds)
                            else
                                if (@xlink:show='new') then
                                    html:link($config, ., ("tei-link4", css:map-rend-to-class(.)), ., @xlink:href, '_new', map {})                                    => model:map($node, $trackIds)
                                else
                                    html:link($config, ., ("tei-link5", css:map-rend-to-class(.)), ., @xlink:href, (), map {})                                    => model:map($node, $trackIds)
                    case element(guibutton) return
                        html:inline($config, ., ("tei-guibutton", "guibutton", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(guilabel) return
                        html:inline($config, ., ("tei-guilabel", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
                    case element(videodata) return
                        model:iframe($config, ., ("tei-videodata2", css:map-rend-to-class(.)), ., @fileref, @width, @depth)                        => model:map($node, $trackIds)
                    case element(abstract) return
                        if ($parameters?path = $parameters?active) then
                            html:omit($config, ., ("tei-abstract1", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                        else
                            html:block($config, ., ("tei-abstract2", css:map-rend-to-class(.)), .)                            => model:map($node, $trackIds)
                    case element(pubdate) return
                        html:inline($config, ., ("tei-pubdate", "pubdate", css:map-rend-to-class(.)), format-date(., '[MNn] [D1], [Y0001]', 'en_US', (), ()))                        => model:map($node, $trackIds)
                    case element(footnote) return
                        html:note($config, ., ("tei-footnote", css:map-rend-to-class(.)), ., (), ())                        => model:map($node, $trackIds)
                    case element(exist:match) return
                        html:match($config, ., .)
                    case element() return
                        html:inline($config, ., ("tei--element", css:map-rend-to-class(.)), .)                        => model:map($node, $trackIds)
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

