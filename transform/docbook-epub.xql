(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/epub";

declare default element namespace "http://docbook.org/ns/docbook";

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
        map:new(($options,
            map {
                "output": ["epub","web"],
                "odd": "/db/apps/tei-publisher/odd/docbook.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    
    return (
        html:prepare($config, $input),
    
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
                        html:document($config, ., ("tei-article"), .)
                    case element(info) return
                        if ($parameters?header='short') then
                            (
                                html:heading($config, ., ("tei-info2"), title, 5),
                                epub:block($config, ., ("tei-info3"), author)
                            )

                        else
                            (: More than one model without predicate found for ident info. Choosing first one. :)
                            epub:block($config, ., ("tei-info1"), (title, author))
                    case element(author) return
                        html:inline($config, ., ("tei-author"), (personname, affiliation))
                    case element(personname) return
                        html:inline($config, ., ("tei-personname"), ('By ', firstname, ' ', surname))
                    case element(affiliation) return
                        html:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if (parent::info and $parameters?header='short') then
                            html:link($config, ., ("tei-title1"), ., $parameters?doc)
                        else
                            html:heading($config, ., ("tei-title2"), ., count(ancestor::section))
                    case element(section) return
                        epub:block($config, ., ("tei-section"), .)
                    case element(para) return
                        html:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        html:inline($config, ., ("tei-emphasis"), .)
                    case element(code) return
                        html:inline($config, ., ("tei-code", "code"), .)
                    case element(figure) return
                        if (title) then
                            html:figure($config, ., ("tei-figure1"), *[not(self::title)], title/node())
                        else
                            html:figure($config, ., ("tei-figure2"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            html:figure($config, ., ("tei-informalfigure1"), *[not(self::caption)], caption/node())
                        else
                            html:figure($config, ., ("tei-informalfigure2"), ., ())
                    case element(imagedata) return
                        html:graphic($config, ., ("tei-imagedata", "img-responsive"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        html:list($config, ., ("tei-itemizedlist"), listitem, ())
                    case element(listitem) return
                        html:listItem($config, ., ("tei-listitem"), ., ())
                    case element(orderedlist) return
                        html:list($config, ., ("tei-orderedlist"), listitem, 'ordered')
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
                            (: No function found for behavior: code :)
                            $config?apply($config, ./node())
                    case element(synopsis) return
                        (: No function found for behavior: code :)
                        $config?apply($config, ./node())
                    case element(function) return
                        html:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        html:inline($config, ., ("tei-command", "code"), .)
                    case element(tag) return
                        html:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            html:link($config, ., ("tei-link1"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            html:link($config, ., ("tei-link2"), ., @xlink:href)
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

