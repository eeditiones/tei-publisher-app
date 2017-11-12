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
                        if ($parameters?header='short') then
                            (
                                fo:heading($config, ., ("tei-info2"), title),
                                fo:block($config, ., ("tei-info3"), author)
                            )

                        else
                            fo:metadata($config, ., ("tei-info4"), .)
                    case element(author) return
                        fo:inline($config, ., ("tei-author"), (personname, affiliation))
                    case element(personname) return
                        fo:inline($config, ., ("tei-personname"), ('By ', firstname, ' ', surname))
                    case element(affiliation) return
                        fo:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if (parent::info and $parameters?header='short') then
                            fo:link($config, ., ("tei-title1"), ., $parameters?doc)
                        else
                            fo:heading($config, ., ("tei-title2"), .)
                    case element(section) return
                        fo:block($config, ., ("tei-section"), .)
                    case element(para) return
                        fo:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        fo:inline($config, ., ("tei-emphasis"), .)
                    case element(code) return
                        fo:inline($config, ., ("tei-code", "code"), .)
                    case element(figure) return
                        if (title) then
                            fo:figure($config, ., ("tei-figure1"), *[not(self::title)], title/node())
                        else
                            fo:figure($config, ., ("tei-figure2"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            fo:figure($config, ., ("tei-informalfigure1"), *[not(self::caption)], caption/node())
                        else
                            fo:figure($config, ., ("tei-informalfigure2"), ., ())
                    case element(imagedata) return
                        fo:graphic($config, ., ("tei-imagedata", "img-responsive"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        fo:list($config, ., ("tei-itemizedlist"), listitem)
                    case element(listitem) return
                        fo:listItem($config, ., ("tei-listitem"), .)
                    case element(orderedlist) return
                        fo:list($config, ., ("tei-orderedlist"), listitem)
                    case element(variablelist) return
                        ext-fo:definitionList($config, ., ("tei-variablelist"), varlistentry)
                    case element(varlistentry) return
                        (
                            ext-fo:definitionTerm($config, ., ("tei-varlistentry1"), term/node()),
                            ext-fo:definitionDef($config, ., ("tei-varlistentry2"), listitem/node())
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
                        ext-fo:code($config, ., ("tei-synopsis"), ., @language)
                    case element(function) return
                        fo:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        fo:inline($config, ., ("tei-command", "code"), .)
                    case element(tag) return
                        fo:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            fo:link($config, ., ("tei-link1"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            fo:link($config, ., ("tei-link2"), ., @xlink:href)
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

