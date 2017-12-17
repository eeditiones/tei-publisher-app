(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/fo";

declare default element namespace "http://docbook.org/ns/docbook";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace fo="http://www.tei-c.org/tei-simple/xquery/functions/fo";

import module namespace ext-fo="http://www.tei-c.org/tei-simple/xquery/ext-fo" at "xmldb:exist:///db/apps/tei-publisher/modules/ext-fo.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": ["fo","print"],
                "odd": "/db/apps/tei-publisher/odd/docbook.odd",
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
    return
    $input !         (
let $node := 
                .
            return
                            typeswitch(.)
                    case element(article) return
                        fo:document($config, ., ("tei-article"), .)
                    case element(info) return
                        if (not(parent::article|parent::book)) then
                            fo:block($config, ., ("tei-info1"), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    fo:heading($config, ., ("tei-info3"), title),
                                    if (author) then
                                        fo:block($config, ., ("tei-info4"), author)
                                    else
                                        ()
                                )

                            else
                                fo:metadata($config, ., ("tei-info5"), .)
                    case element(author) return
                        if (preceding-sibling::author) then
                            fo:inline($config, ., ("tei-author1"), (', ', personname, affiliation))
                        else
                            fo:inline($config, ., ("tei-author2"), (personname, affiliation))
                    case element(personname) return
                        fo:inline($config, ., ("tei-personname"), (firstname, ' ', surname))
                    case element(affiliation) return
                        fo:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if (parent::note) then
                            fo:inline($config, ., ("tei-title1"), .)
                        else
                            if (parent::info and $parameters?header='short') then
                                fo:link($config, ., ("tei-title2"), ., $parameters?doc)
                            else
                                fo:heading($config, ., ("tei-title3", "title"), .)
                    case element(section) return
                        fo:block($config, ., ("tei-section"), .)
                    case element(para) return
                        fo:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        if (@role='bold') then
                            fo:inline($config, ., ("tei-emphasis1"), .)
                        else
                            fo:inline($config, ., ("tei-emphasis2"), .)
                    case element(code) return
                        fo:inline($config, ., ("tei-code", "code"), .)
                    case element(figure) return
                        if (title|info/title) then
                            fo:figure($config, ., ("tei-figure1", "figure"), *[not(self::title|self::info)], title/node()|info/title/node())
                        else
                            fo:figure($config, ., ("tei-figure2"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            fo:figure($config, ., ("tei-informalfigure1", "figure"), *[not(self::caption)], caption/node())
                        else
                            fo:figure($config, ., ("tei-informalfigure2", "figure"), ., ())
                    case element(imagedata) return
                        fo:graphic($config, ., ("tei-imagedata", "img-responsive"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        fo:list($config, ., ("tei-itemizedlist"), listitem)
                    case element(listitem) return
                        fo:listItem($config, ., ("tei-listitem"), .)
                    case element(orderedlist) return
                        fo:list($config, ., ("tei-orderedlist"), listitem)
                    case element(procedure) return
                        fo:list($config, ., ("tei-procedure"), step)
                    case element(step) return
                        fo:listItem($config, ., ("tei-step"), .)
                    case element(variablelist) return
                        ext-fo:definitionList($config, ., ("tei-variablelist"), varlistentry)
                    case element(varlistentry) return
                        (
                            ext-fo:definitionTerm($config, ., ("tei-varlistentry1", "term"), term/node()),
                            ext-fo:definitionDef($config, ., ("tei-varlistentry2", "varlistentry"), listitem/node())
                        )

                    case element(table) return
                        if (title) then
                            (
                                fo:heading($config, ., ("tei-table1"), title),
                                fo:table($config, ., ("tei-table2"), .//tr)
                            )

                        else
                            fo:table($config, ., ("tei-table3", "table"), .//tr)
                    case element(informaltable) return
                        fo:table($config, ., ("tei-informaltable", "table"), .//tr)
                    case element(tr) return
                        fo:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        if (parent::tr/parent::thead) then
                            fo:cell($config, ., ("tei-td1"), ., ())
                        else
                            fo:cell($config, ., ("tei-td2"), ., ())
                    case element(programlisting) return
                        fo:block($config, ., ("tei-programlisting3", "programlisting"), .)
                    case element(synopsis) return
                        (: More than one model without predicate found for ident synopsis. Choosing first one. :)
                        fo:block($config, ., ("tei-synopsis1", "programlisting"), .)
                    case element(example) return
                        fo:figure($config, ., ("tei-example"), *[not(self::title|self::info)], info/title/node()|title/node())
                    case element(function) return
                        fo:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        fo:inline($config, ., ("tei-command", "code"), .)
                    case element(parameter) return
                        fo:inline($config, ., ("tei-parameter", "code"), .)
                    case element(filename) return
                        fo:inline($config, ., ("tei-filename", "code"), .)
                    case element(note) return
                        (: No function found for behavior: panel :)
                        $config?apply($config, ./node())
                    case element(tag) return
                        fo:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            fo:link($config, ., ("tei-link1"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            fo:link($config, ., ("tei-link2"), ., @xlink:href)
                    case element(guibutton) return
                        fo:inline($config, ., ("tei-guibutton"), .)
                    case element(guilabel) return
                        fo:inline($config, ., ("tei-guilabel"), .)
                    case element(videodata) return
                        (: No function found for behavior: iframe :)
                        $config?apply($config, ./node())
                    case element() return
                        fo:inline($config, ., ("tei--element"), .)
                    case text() | xs:anyAtomicType return
                        fo:escapeChars(.)
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
                fo:escapeChars(.)
    )
};

