(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-simple/odd/compiled/documentation.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/tei-simple/models/documentation.odd";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/css.xql";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/latex-functions.xql";

import module namespace ext-latex="http://www.tei-c.org/tei-simple/xquery/ext-latex" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/../modules/ext-latex.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": ["latex","print"],
                "odd": "/db/apps/tei-simple/odd/compiled/documentation.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
        return
            model:apply($config, $input)
                        
};

declare function model:apply($config as map(*), $input as node()*) {
    let $parameters := 
        if (exists($config?parameters)) then $config?parameters else map {}
    return
    $input !         (
            typeswitch(.)
                case element(abbr) return
                    latex:inline($config, ., "abbr", .)
                case element(add) return
                    latex:inline($config, ., "add", .)
                case element(address) return
                    latex:block($config, ., "address", .)
                case element(addrLine) return
                    latex:block($config, ., "addrLine", .)
                case element(author) return
                    if (ancestor::teiHeader) then
                        latex:omit($config, ., "author1", .)
                    else
                        latex:inline($config, ., "author2", .)
                case element(bibl) return
                    if (parent::listBibl) then
                        latex:listItem($config, ., "bibl1", .)
                    else
                        latex:inline($config, ., "bibl2", .)
                case element(cb) return
                    latex:break($config, ., "cb", ., 'column', @n)
                case element(choice) return
                    if (sic and corr) then
                        latex:alternate($config, ., "choice4", ., corr[1], sic[1])
                    else
                        if (abbr and expan) then
                            latex:alternate($config, ., "choice5", ., expan[1], abbr[1])
                        else
                            if (orig and reg) then
                                latex:alternate($config, ., "choice6", ., reg[1], orig[1])
                            else
                                $config?apply($config, ./node())
                case element(cit) return
                    if (child::quote and child::bibl) then
                        (: Insert citation :)
                        latex:cit($config, ., "cit", .)
                    else
                        $config?apply($config, ./node())
                case element(corr) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        (: simple inline, if in parent choice. :)
                        latex:inline($config, ., "corr1", .)
                    else
                        latex:inline($config, ., "corr2", .)
                case element(date) return
                    if (text()) then
                        latex:inline($config, ., "date1", .)
                    else
                        if (@when and not(text())) then
                            latex:inline($config, ., "date2", @when)
                        else
                            if (text()) then
                                latex:inline($config, ., "date4", .)
                            else
                                $config?apply($config, ./node())
                case element(del) return
                    latex:inline($config, ., "del", .)
                case element(desc) return
                    latex:inline($config, ., "desc", .)
                case element(expan) return
                    latex:inline($config, ., "expan", .)
                case element(foreign) return
                    latex:inline($config, ., "foreign", .)
                case element(gap) return
                    if (desc) then
                        latex:inline($config, ., "gap1", .)
                    else
                        if (@extent) then
                            latex:inline($config, ., "gap2", @extent)
                        else
                            latex:inline($config, ., "gap3", .)
                case element(graphic) return
                    latex:graphic($config, ., "graphic", ., @url, @width, @height, @scale, desc)
                case element(head) return
                    if (parent::figure) then
                        latex:block($config, ., "head1", .)
                    else
                        if (parent::table) then
                            latex:block($config, ., "head2", .)
                        else
                            if (parent::lg) then
                                latex:block($config, ., "head3", .)
                            else
                                if (parent::list) then
                                    latex:block($config, ., "head4", .)
                                else
                                    if (parent::div) then
                                        latex:heading($config, ., "head5", .)
                                    else
                                        latex:block($config, ., "head6", .)
                case element(hi) return
                    if (@rendition) then
                        latex:inline($config, ., css:get-rendition(., "hi1"), .)
                    else
                        if (not(@rendition)) then
                            latex:inline($config, ., "hi2", .)
                        else
                            $config?apply($config, ./node())
                case element(item) return
                    latex:listItem($config, ., "item", .)
                case element(l) return
                    latex:block($config, ., css:get-rendition(., "l"), .)
                case element(label) return
                    latex:inline($config, ., "label", .)
                case element(lb) return
                    latex:break($config, ., css:get-rendition(., "lb"), ., 'line', @n)
                case element(lg) return
                    latex:block($config, ., "lg", .)
                case element(list) return
                    if (@rendition) then
                        latex:list($config, ., css:get-rendition(., "list1"), item)
                    else
                        if (not(@rendition)) then
                            latex:list($config, ., "list2", item)
                        else
                            $config?apply($config, ./node())
                case element(listBibl) return
                    if (bibl) then
                        latex:list($config, ., "listBibl1", bibl)
                    else
                        latex:block($config, ., "listBibl2", .)
                case element(measure) return
                    latex:inline($config, ., "measure", .)
                case element(milestone) return
                    latex:inline($config, ., "milestone", .)
                case element(name) return
                    latex:inline($config, ., "name", .)
                case element(note) return
                    if (@place) then
                        latex:note($config, ., "note1", ., @place, @n)
                    else
                        if (parent::div and not(@place)) then
                            latex:block($config, ., "note2", .)
                        else
                            if (not(@place)) then
                                latex:inline($config, ., "note3", .)
                            else
                                $config?apply($config, ./node())
                case element(num) return
                    latex:inline($config, ., "num", .)
                case element(orig) return
                    latex:inline($config, ., "orig", .)
                case element(p) return
                    latex:paragraph($config, ., css:get-rendition(., "p"), .)
                case element(pb) return
                    latex:break($config, ., css:get-rendition(., "pb"), ., 'page', (concat(if(@n) then     concat(@n,' ') else '',if(@facs) then     concat('@',@facs) else '')))
                case element(publisher) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "publisher", .)
                    else
                        $config?apply($config, ./node())
                case element(pubPlace) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "pubPlace", .)
                    else
                        $config?apply($config, ./node())
                case element(q) return
                    if (l) then
                        latex:block($config, ., css:get-rendition(., "q1"), .)
                    else
                        if (ancestor::p or ancestor::cell) then
                            latex:inline($config, ., css:get-rendition(., "q2"), .)
                        else
                            latex:block($config, ., css:get-rendition(., "q3"), .)
                case element(quote) return
                    if (ancestor::p) then
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        latex:inline($config, ., css:get-rendition(., "quote1"), .)
                    else
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        latex:block($config, ., css:get-rendition(., "quote2"), .)
                case element(ref) return
                    if (not(@target)) then
                        latex:inline($config, ., "ref1", .)
                    else
                        if (not(text())) then
                            latex:link($config, ., "ref2", @target, @target)
                        else
                            latex:link($config, ., "ref3", ., @target)
                case element(reg) return
                    latex:inline($config, ., "reg", .)
                case element(rs) return
                    latex:inline($config, ., "rs", .)
                case element(sic) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        latex:inline($config, ., "sic1", .)
                    else
                        latex:inline($config, ., "sic2", .)
                case element(sp) return
                    latex:block($config, ., "sp", .)
                case element(speaker) return
                    latex:block($config, ., "speaker", .)
                case element(stage) return
                    latex:block($config, ., "stage", .)
                case element(time) return
                    latex:inline($config, ., "time", .)
                case element(title) return
                    if (parent::titleStmt/parent::fileDesc) then
                        (
                            if (preceding-sibling::title) then
                                latex:text($config, ., "title1", ' — ')
                            else
                                (),
                            latex:inline($config, ., "title2", .)
                        )

                    else
                        if (not(@level) and parent::bibl) then
                            latex:inline($config, ., "title1", .)
                        else
                            if (@level='m' or not(@level)) then
                                (
                                    latex:inline($config, ., "title1", .),
                                    if (ancestor::biblStruct or       ancestor::biblFull) then
                                        latex:text($config, ., "title2", ', ')
                                    else
                                        ()
                                )

                            else
                                if (@level='s' or @level='j') then
                                    (
                                        latex:inline($config, ., "title1", .),
                                        if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                            latex:text($config, ., "title2", ', ')
                                        else
                                            ()
                                    )

                                else
                                    if (@level='u' or @level='a') then
                                        (
                                            latex:inline($config, ., "title1", .),
                                            if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                                latex:text($config, ., "title2", '. ')
                                            else
                                                ()
                                        )

                                    else
                                        latex:inline($config, ., "title2", .)
                case element(unclear) return
                    latex:inline($config, ., "unclear", .)
                case element(fileDesc) return
                    latex:title($config, ., "fileDesc", titleStmt)
                case element(encodingDesc) return
                    latex:omit($config, ., "encodingDesc", .)
                case element(profileDesc) return
                    latex:omit($config, ., "profileDesc", .)
                case element(revisionDesc) return
                    latex:omit($config, ., "revisionDesc", .)
                case element(teiHeader) return
                    latex:metadata($config, ., "teiHeader", .)
                case element(g) return
                    if (not(text())) then
                        latex:glyph($config, ., "g1", @ref)
                    else
                        latex:inline($config, ., "g2", .)
                case element(addSpan) return
                    latex:anchor($config, ., "addSpan", ., @xml:id)
                case element(am) return
                    latex:inline($config, ., "am", .)
                case element(ex) return
                    latex:inline($config, ., "ex", .)
                case element(fw) return
                    if (ancestor::p or ancestor::ab) then
                        latex:inline($config, ., "fw1", .)
                    else
                        latex:block($config, ., "fw2", .)
                case element(handShift) return
                    latex:inline($config, ., "handShift", .)
                case element(space) return
                    latex:inline($config, ., "space", .)
                case element(subst) return
                    latex:inline($config, ., "subst", .)
                case element(supplied) return
                    if (parent::choice) then
                        latex:inline($config, ., "supplied1", .)
                    else
                        if (@reason='damage') then
                            latex:inline($config, ., "supplied2", .)
                        else
                            if (@reason='illegible' or not(@reason)) then
                                latex:inline($config, ., "supplied3", .)
                            else
                                if (@reason='omitted') then
                                    latex:inline($config, ., "supplied4", .)
                                else
                                    latex:inline($config, ., "supplied5", .)
                case element(c) return
                    latex:inline($config, ., "c", .)
                case element(pc) return
                    latex:inline($config, ., "pc", .)
                case element(s) return
                    latex:inline($config, ., "s", .)
                case element(w) return
                    latex:inline($config, ., "w", .)
                case element(ab) return
                    latex:paragraph($config, ., "ab", .)
                case element(anchor) return
                    latex:anchor($config, ., "anchor", ., @xml:id)
                case element(seg) return
                    latex:inline($config, ., css:get-rendition(., "seg"), .)
                case element(actor) return
                    latex:inline($config, ., "actor", .)
                case element(castGroup) return
                    if (child::*) then
                        (: Insert list. :)
                        latex:list($config, ., "castGroup", castItem|castGroup)
                    else
                        $config?apply($config, ./node())
                case element(castItem) return
                    (: Insert item, rendered as described in parent list rendition. :)
                    latex:listItem($config, ., "castItem", .)
                case element(castList) return
                    if (child::*) then
                        latex:list($config, ., css:get-rendition(., "castList"), castItem)
                    else
                        $config?apply($config, ./node())
                case element(role) return
                    latex:block($config, ., "role", .)
                case element(roleDesc) return
                    latex:block($config, ., "roleDesc", .)
                case element(spGrp) return
                    latex:block($config, ., "spGrp", .)
                case element(argument) return
                    latex:block($config, ., "argument", .)
                case element(back) return
                    latex:block($config, ., "back", .)
                case element(body) return
                    (
                        latex:index($config, ., "body1", ., 'toc'),
                        latex:block($config, ., "body2", .)
                    )

                case element(byline) return
                    latex:block($config, ., "byline", .)
                case element(closer) return
                    latex:block($config, ., "closer", .)
                case element(dateline) return
                    latex:block($config, ., "dateline", .)
                case element(div) return
                    if (@type='title_page') then
                        latex:block($config, ., "div1", .)
                    else
                        if (parent::body or parent::front or parent::back) then
                            latex:section($config, ., "div2", .)
                        else
                            latex:block($config, ., "div3", .)
                case element(docAuthor) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "docAuthor1", .)
                    else
                        latex:inline($config, ., "docAuthor2", .)
                case element(docDate) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "docDate1", .)
                    else
                        latex:inline($config, ., "docDate2", .)
                case element(docEdition) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "docEdition1", .)
                    else
                        latex:inline($config, ., "docEdition2", .)
                case element(docImprint) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "docImprint1", .)
                    else
                        latex:inline($config, ., "docImprint2", .)
                case element(docTitle) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        latex:omit($config, ., "docTitle1", .)
                    else
                        latex:block($config, ., css:get-rendition(., "docTitle2"), .)
                case element(epigraph) return
                    latex:block($config, ., "epigraph", .)
                case element(floatingText) return
                    latex:block($config, ., "floatingText", .)
                case element(front) return
                    latex:block($config, ., "front", .)
                case element(group) return
                    latex:block($config, ., "group", .)
                case element(imprimatur) return
                    latex:block($config, ., "imprimatur", .)
                case element(opener) return
                    latex:block($config, ., "opener", .)
                case element(postscript) return
                    latex:block($config, ., "postscript", .)
                case element(salute) return
                    if (parent::closer) then
                        latex:inline($config, ., "salute1", .)
                    else
                        latex:block($config, ., "salute2", .)
                case element(signed) return
                    if (parent::closer) then
                        latex:block($config, ., "signed1", .)
                    else
                        latex:inline($config, ., "signed2", .)
                case element(TEI) return
                    latex:document($config, ., "TEI", .)
                case element(text) return
                    latex:body($config, ., "text", .)
                case element(titlePage) return
                    latex:block($config, ., css:get-rendition(., "titlePage"), .)
                case element(titlePart) return
                    latex:block($config, ., css:get-rendition(., "titlePart"), .)
                case element(trailer) return
                    latex:block($config, ., "trailer", .)
                case element(cell) return
                    (: Insert table cell. :)
                    latex:cell($config, ., "cell", .)
                case element(figDesc) return
                    latex:inline($config, ., "figDesc", .)
                case element(figure) return
                    if (head or @rendition='simple:display') then
                        latex:block($config, ., "figure1", .)
                    else
                        latex:inline($config, ., "figure2", .)
                case element(formula) return
                    if (@rendition='simple:display') then
                        latex:block($config, ., "formula1", .)
                    else
                        latex:inline($config, ., "formula2", .)
                case element(row) return
                    if (@role='label') then
                        latex:row($config, ., "row1", .)
                    else
                        (: Insert table row. :)
                        latex:row($config, ., "row2", .)
                case element(table) return
                    latex:table($config, ., "table", .)
                case element(rhyme) return
                    latex:inline($config, ., "rhyme", .)
                case element(code) return
                    if (parent::cell|parent::p|parent::ab) then
                        latex:inline($config, ., "code1", .)
                    else
                        ext-latex:code($config, ., "code2", ., @lang)
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

