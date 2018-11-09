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

        
        <t xmlns=""><iframe src="{$config?apply-children($config, $node, $src)}" width="{$config?apply-children($config, $node, $width)}" height="{$config?apply-children($config, $node, $height)}" frameborder="0" gesture="media" allow="encrypted-media" allowfullscreen="allowfullscreen"> </iframe></t>/*
    )
};

(: generated template function for element spec: title :)
declare %private function model:template1($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><h1><pb-link path="{$config?apply-children($config, $node, $params?path)}" emit="transcription">{$config?apply-children($config, $node, $params?content)}</pb-link></h1></t>/*
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
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
    return
    $input !         (
            let $node := 
                .
            return
                            typeswitch(.)
                    case element(article) return
                        if ($parameters?mode='summary') then
                            html:block($config, ., ("tei-article2"), info)
                        else
                            html:document($config, ., ("tei-article3"), .)
                    case element(info) return
                        if (not(parent::article or parent::book)) then
                            html:block($config, ., ("tei-info2"), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    html:heading($config, ., ("tei-info4"), title, 5),
                                    if (author) then
                                        html:block($config, ., ("tei-info5"), author)
                                    else
                                        ()
                                )

                            else
                                html:block($config, ., ("tei-info6"), (title, author, pubdate, abstract))
                    case element(author) return
                        if (preceding-sibling::author) then
                            html:inline($config, ., ("tei-author3"), (', ', personname, affiliation))
                        else
                            html:inline($config, ., ("tei-author4"), (personname, affiliation))
                    case element(personname) return
                        html:inline($config, ., ("tei-personname"), (firstname, ' ', surname))
                    case element(affiliation) return
                        html:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if ($parameters?mode='summary') then
                            let $params := 
                                map {
                                    "content": node(),
                                    "path": $parameters?path
                                }

                                                        let $content := 
                                model:template1($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-title2", "articletitle"), $content)
                        else
                            if ($parameters?mode='breadcrumbs') then
                                html:inline($config, ., ("tei-title3"), .)
                            else
                                if (parent::note) then
                                    html:inline($config, ., ("tei-title4"), .)
                                else
                                    if (parent::info and $parameters?header='short') then
                                        html:link($config, ., ("tei-title5"), ., $parameters?doc)
                                    else
                                        html:heading($config, ., ("tei-title6", "title"), ., if ($parameters?view='single') then   count(ancestor::section) + 1 else  count(ancestor::section))
                    case element(section) return
                        if ($parameters?mode='breadcrumbs') then
                            (
                                html:inline($config, ., ("tei-section1"), $parameters?root/ancestor::section/title),
                                html:inline($config, ., ("tei-section2"), title)
                            )

                        else
                            html:block($config, ., ("tei-section3"), .)
                    case element(para) return
                        html:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        if (@role='bold') then
                            html:inline($config, ., ("tei-emphasis1"), .)
                        else
                            html:inline($config, ., ("tei-emphasis2"), .)
                    case element(code) return
                        html:inline($config, ., ("tei-code2", "code"), .)
                    case element(figure) return
                        if (title|info/title) then
                            html:figure($config, ., ("tei-figure2", "figure"), *[not(self::title|self::info)], title/node()|info/title/node())
                        else
                            html:figure($config, ., ("tei-figure3"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            html:figure($config, ., ("tei-informalfigure1", "figure"), *[not(self::caption)], caption/node())
                        else
                            html:figure($config, ., ("tei-informalfigure2", "figure"), ., ())
                    case element(imagedata) return
                        html:graphic($config, ., ("tei-imagedata"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        html:list($config, ., ("tei-itemizedlist"), listitem, ())
                    case element(listitem) return
                        html:listItem($config, ., ("tei-listitem"), ., ())
                    case element(orderedlist) return
                        html:list($config, ., ("tei-orderedlist"), listitem, 'ordered')
                    case element(procedure) return
                        html:list($config, ., ("tei-procedure"), step, 'ordered')
                    case element(step) return
                        html:listItem($config, ., ("tei-step"), ., ())
                    case element(variablelist) return
                        model:definitionList($config, ., ("tei-variablelist"), varlistentry)
                    case element(varlistentry) return
                        model:definition($config, ., ("tei-varlistentry"), listitem/node(), term/node())
                    case element(table) return
                        if (title) then
                            (
                                html:heading($config, ., ("tei-table1"), title, ()),
                                html:table($config, ., ("tei-table2"), .//tr)
                            )

                        else
                            html:table($config, ., ("tei-table3", "table"), .//tr)
                    case element(informaltable) return
                        html:table($config, ., ("tei-informaltable", "table"), .//tr)
                    case element(tr) return
                        html:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        if (parent::tr/parent::thead) then
                            html:cell($config, ., ("tei-td1"), ., ())
                        else
                            html:cell($config, ., ("tei-td2"), ., ())
                    case element(programlisting) return
                        if (parent::cell|parent::para|parent::ab) then
                            html:inline($config, ., ("tei-programlisting3", "code"), .)
                        else
                            html:webcomponent($config, ., ("tei-programlisting4"), text(), 'pb-code-highlight', map {"lang": @language})
                    case element(synopsis) return
                        html:webcomponent($config, ., ("tei-synopsis4"), ., 'pb-code-highlight', map {"lang": @language})
                    case element(example) return
                        html:figure($config, ., ("tei-example"), *[not(self::title|self::info)], info/title/node()|title/node())
                    case element(function) return
                        html:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        html:inline($config, ., ("tei-command", "code"), .)
                    case element(parameter) return
                        html:inline($config, ., ("tei-parameter", "code"), .)
                    case element(filename) return
                        html:inline($config, ., ("tei-filename", "code"), .)
                    case element(note) return
                        html:webcomponent($config, ., ("tei-note3", "note"), *[not(self::title)], 'paper-card', map {"heading": title})
                    case element(tag) return
                        html:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            html:link($config, ., ("tei-link1"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            html:link($config, ., ("tei-link2"), ., @xlink:href)
                    case element(guibutton) return
                        html:inline($config, ., ("tei-guibutton"), .)
                    case element(guilabel) return
                        html:inline($config, ., ("tei-guilabel"), .)
                    case element(videodata) return
                        model:iframe($config, ., ("tei-videodata2"), ., @fileref, @width, @depth)
                    case element(abstract) return
                        if ($parameters?path = $parameters?active) then
                            html:omit($config, ., ("tei-abstract1"), .)
                        else
                            html:block($config, ., ("tei-abstract2"), .)
                    case element(pubdate) return
                        html:inline($config, ., ("tei-pubdate", "pubdate"), format-date(., '[MNn] [D1], [Y0001]', 'en_US', (), ()))
                    case element(exist:match) return
                        html:match($config, ., .)
                    case element() return
                        html:inline($config, ., ("tei--element"), .)
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

