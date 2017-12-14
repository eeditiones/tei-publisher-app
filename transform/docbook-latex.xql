(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/latex";

declare default element namespace "http://docbook.org/ns/docbook";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";

import module namespace ext-latex="http://www.tei-c.org/tei-simple/xquery/ext-latex" at "xmldb:exist:///db/apps/tei-publisher/modules/ext-latex.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": ["latex","print"],
                "odd": "/db/apps/tei-publisher/odd/docbook.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    let $config := latex:init($config, $input)
    
    return (
        
        let $output := model:apply($config, $input)
        return
            $output
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
                        latex:document($config, ., ("tei-article"), .)
                    case element(info) return
                        if (not(parent::article|parent::book)) then
                            latex:block($config, ., ("tei-info1"), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    latex:heading($config, ., ("tei-info3"), title),
                                    if (author) then
                                        latex:block($config, ., ("tei-info4"), author)
                                    else
                                        ()
                                )

                            else
                                latex:metadata($config, ., ("tei-info5"), .)
                    case element(author) return
                        if (preceding-sibling::author) then
                            latex:inline($config, ., ("tei-author1"), (', ', personname, affiliation))
                        else
                            latex:inline($config, ., ("tei-author2"), (personname, affiliation))
                    case element(personname) return
                        latex:inline($config, ., ("tei-personname"), (firstname, ' ', surname))
                    case element(affiliation) return
                        latex:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if (parent::note) then
                            latex:inline($config, ., ("tei-title1"), .)
                        else
                            if (parent::info and $parameters?header='short') then
                                latex:link($config, ., ("tei-title2"), ., $parameters?doc)
                            else
                                latex:heading($config, ., ("tei-title3", "title"), .)
                    case element(section) return
                        latex:block($config, ., ("tei-section"), .)
                    case element(para) return
                        latex:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        if (@role='bold') then
                            latex:inline($config, ., ("tei-emphasis1"), .)
                        else
                            latex:inline($config, ., ("tei-emphasis2"), .)
                    case element(code) return
                        latex:inline($config, ., ("tei-code", "code"), .)
                    case element(figure) return
                        if (title|info/title) then
                            latex:figure($config, ., ("tei-figure1", "figure"), *[not(self::title|self::info)], title/node()|info/title/node())
                        else
                            latex:figure($config, ., ("tei-figure2"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            latex:figure($config, ., ("tei-informalfigure1", "figure"), *[not(self::caption)], caption/node())
                        else
                            latex:figure($config, ., ("tei-informalfigure2", "figure"), ., ())
                    case element(imagedata) return
                        latex:graphic($config, ., ("tei-imagedata", "img-responsive"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        latex:list($config, ., ("tei-itemizedlist"), listitem)
                    case element(listitem) return
                        latex:listItem($config, ., ("tei-listitem"), .)
                    case element(orderedlist) return
                        latex:list($config, ., ("tei-orderedlist"), listitem)
                    case element(procedure) return
                        latex:list($config, ., ("tei-procedure"), step)
                    case element(step) return
                        latex:listItem($config, ., ("tei-step"), .)
                    case element(variablelist) return
                        (: No function found for behavior: definitionList :)
                        $config?apply($config, ./node())
                    case element(varlistentry) return
                        (
                            (: No function found for behavior: definitionTerm :)
                            $config?apply($config, ./node()),
                            (: No function found for behavior: definitionDef :)
                            $config?apply($config, ./node())
                        )

                    case element(table) return
                        if (title) then
                            (
                                latex:heading($config, ., ("tei-table1"), title),
                                latex:table($config, ., ("tei-table2"), .//tr)
                            )

                        else
                            latex:table($config, ., ("tei-table3", "table"), .//tr)
                    case element(informaltable) return
                        latex:table($config, ., ("tei-informaltable", "table"), .//tr)
                    case element(tr) return
                        latex:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        if (parent::tr/parent::thead) then
                            latex:cell($config, ., ("tei-td1"), ., ())
                        else
                            latex:cell($config, ., ("tei-td2"), ., ())
                    case element(programlisting) return
                        latex:block($config, ., ("tei-programlisting3", "programlisting"), .)
                    case element(synopsis) return
                        (: More than one model without predicate found for ident synopsis. Choosing first one. :)
                        latex:block($config, ., ("tei-synopsis1", "programlisting"), .)
                    case element(example) return
                        latex:figure($config, ., ("tei-example"), *[not(self::title|self::info)], info/title/node()|title/node())
                    case element(function) return
                        latex:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        latex:inline($config, ., ("tei-command", "code"), .)
                    case element(parameter) return
                        latex:inline($config, ., ("tei-parameter", "code"), .)
                    case element(filename) return
                        latex:inline($config, ., ("tei-filename", "code"), .)
                    case element(note) return
                        (: No function found for behavior: panel :)
                        $config?apply($config, ./node())
                    case element(tag) return
                        latex:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            latex:link($config, ., ("tei-link1"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            latex:link($config, ., ("tei-link2"), ., @xlink:href)
                    case element(guibutton) return
                        latex:inline($config, ., ("tei-guibutton"), .)
                    case element(guilabel) return
                        latex:inline($config, ., ("tei-guilabel"), .)
                    case element() return
                        latex:inline($config, ., ("tei--element"), .)
                    case text() | xs:anyAtomicType return
                        latex:escapeChars(.)
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
                latex:escapeChars(.)
    )
};

