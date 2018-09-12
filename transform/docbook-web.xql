(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/web";

declare default element namespace "http://docbook.org/ns/docbook";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

import module namespace ext-html="http://www.tei-c.org/tei-simple/xquery/ext-html" at "xmldb:exist:///db/apps/tei-publisher/modules/ext-html.xql";

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
                        html:document($config, ., ("tei-article"), .)
                    case element(info) return
                        if (not(parent::article|parent::book)) then
                            html:block($config, ., ("tei-info1"), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    html:heading($config, ., ("tei-info3"), title, 5),
                                    if (author) then
                                        html:block($config, ., ("tei-info4"), author)
                                    else
                                        ()
                                )

                            else
                                html:metadata($config, ., ("tei-info5"), .)
                    case element(author) return
                        if (preceding-sibling::author) then
                            html:inline($config, ., ("tei-author1"), (', ', personname, affiliation))
                        else
                            html:inline($config, ., ("tei-author2"), (personname, affiliation))
                    case element(personname) return
                        html:inline($config, ., ("tei-personname"), (firstname, ' ', surname))
                    case element(affiliation) return
                        html:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if ($parameters?mode='breadcrumbs') then
                            html:inline($config, ., ("tei-title1"), .)
                        else
                            if (parent::note) then
                                html:inline($config, ., ("tei-title2"), .)
                            else
                                if (parent::info and $parameters?header='short') then
                                    html:link($config, ., ("tei-title3"), ., $parameters?doc)
                                else
                                    html:heading($config, ., ("tei-title4", "title"), ., count(ancestor::section))
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
                        html:inline($config, ., ("tei-code", "code"), .)
                    case element(figure) return
                        if (title|info/title) then
                            html:figure($config, ., ("tei-figure1", "figure"), *[not(self::title|self::info)], title/node()|info/title/node())
                        else
                            html:figure($config, ., ("tei-figure2"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            html:figure($config, ., ("tei-informalfigure1", "figure"), *[not(self::caption)], caption/node())
                        else
                            html:figure($config, ., ("tei-informalfigure2", "figure"), ., ())
                    case element(imagedata) return
                        html:graphic($config, ., ("tei-imagedata", "img-responsive"), ., @fileref, (), (), (), ())
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
                        ext-html:definitionList($config, ., ("tei-variablelist"), varlistentry)
                    case element(varlistentry) return
                        (
                            ext-html:definitionTerm($config, ., ("tei-varlistentry1", "term"), term/node()),
                            ext-html:definitionDef($config, ., ("tei-varlistentry2", "varlistentry"), listitem/node())
                        )

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
                        (: More than one model without predicate found for ident programlisting. Choosing first one. :)
                        if (parent::cell|parent::para|parent::ab) then
                            html:inline($config, ., ("tei-programlisting1", "code"), .)
                        else
                            html:webcomponent($config, ., ("tei-programlisting2"), ., 'pb-code-highlight', map {"lang": @language})
                    case element(synopsis) return
                        html:webcomponent($config, ., ("tei-synopsis2"), ., 'pb-code-highlight', map {"lang": @language})
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
                        (: More than one model without predicate found for ident note. Choosing first one. :)
                        html:webcomponent($config, ., ("tei-note1", "note"), *[not(self::title)], 'paper-card', map {"heading": title})
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
                        ext-html:iframe($config, ., ("tei-videodata"), ., @fileref, @width, @depth)
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

