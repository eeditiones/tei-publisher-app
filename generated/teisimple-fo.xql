(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-simple/odd/teisimple.odd
 :)
xquery version "3.0";

module namespace model="http://www.tei-c.org/tei-simple/models/teisimple.odd";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace fo="http://www.tei-c.org/tei-simple/xquery/functions/fo" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/fo-functions.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": "print",
                "odd": "/db/apps/tei-simple/odd/teisimple.odd",
                "apply": model:apply#2
            }
        ))
        return
            model:apply($config, $input)
                        
};

declare function model:apply($config as map(*), $input as node()*) {
    $input !     (
        typeswitch(.)
            case element(ab) return
                fo:paragraph($config, ., "ab", .)
            case element(abbr) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    fo:omit($config, ., "abbr1")
                else
                    fo:inline($config, ., "abbr2", .)
            case element(actor) return
                fo:inline($config, ., "actor", .)
            case element(add) return
                fo:inline($config, ., "add", .)
            case element(address) return
                fo:block($config, ., "address", .)
            case element(addrLine) return
                fo:block($config, ., "addrLine", .)
            case element(addSpan) return
                fo:anchor($config, ., "addSpan", @xml:id)
            case element(am) return
                fo:inline($config, ., "am", .)
            case element(anchor) return
                fo:anchor($config, ., "anchor", @xml:id)
            case element(argument) return
                fo:block($config, ., "argument", .)
            case element(author) return
                if (ancestor::teiHeader) then
                    fo:omit($config, ., "author1")
                else
                    fo:inline($config, ., "author2", .)
            case element(back) return
                fo:block($config, ., "back", .)
            case element(bibl) return
                fo:inline($config, ., "bibl", .)
            case element(body) return
                (
                    fo:index($config, ., "body1", ., 'toc'),
                    fo:block($config, ., "body2", .)
                )

            case element(byline) return
                fo:block($config, ., "byline", .)
            case element(c) return
                fo:inline($config, ., "c", .)
            case element(castGroup) return
                if (child::*) then
                    (: Insert list. :)
                    fo:list($config, ., "castGroup", castItem|castGroup)
                else
                    $config?apply($config, ./node())
            case element(castItem) return
                (: Insert item, rendered as described in parent list rendition. :)
                fo:listItem($config, ., "castItem", .)
            case element(castList) return
                if (child::*) then
                    fo:list($config, ., fo:get-rendition(., "castList"), castItem)
                else
                    $config?apply($config, ./node())
            case element(cb) return
                fo:break($config, ., "cb", 'column', @n)
            case element(cell) return
                (: Insert table cell. :)
                fo:cell($config, ., "cell", .)
            case element(choice) return
                if (sic and corr) then
                    fo:alternate($config, ., "choice1", corr[1], sic[1])
                else
                    if (abbr and expan) then
                        fo:alternate($config, ., "choice2", expan[1], abbr[1])
                    else
                        if (orig and reg) then
                            fo:alternate($config, ., "choice3", reg[1], orig[1])
                        else
                            $config?apply($config, ./node())
            case element(cit) return
                if (child::quote and child::bibl) then
                    (: Insert cit. :)
                    fo:cit($config, ., "cit", .)
                else
                    $config?apply($config, ./node())
            case element(closer) return
                fo:block($config, ., "closer", .)
            case element(corr) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    (: Omit, if handled in parent choice. :)
                    fo:omit($config, ., "corr1")
                else
                    fo:inline($config, ., "corr2", .)
            case element(date) return
                if (text()) then
                    fo:inline($config, ., "date1", .)
                else
                    if (@when and not(text())) then
                        fo:inline($config, ., "date2", @when)
                    else
                        if (text()) then
                            fo:inline($config, ., "date4", .)
                        else
                            $config?apply($config, ./node())
            case element(dateline) return
                fo:block($config, ., "dateline", .)
            case element(del) return
                fo:inline($config, ., "del", .)
            case element(desc) return
                fo:omit($config, ., "desc")
            case element(div) return
                if (@type='title_page') then
                    fo:block($config, ., "div1", .)
                else
                    fo:section($config, ., "div2", .)
            case element(docAuthor) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "docAuthor1")
                else
                    fo:inline($config, ., "docAuthor2", .)
            case element(docDate) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "docDate1")
                else
                    fo:inline($config, ., "docDate2", .)
            case element(docEdition) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "docEdition1")
                else
                    fo:inline($config, ., "docEdition2", .)
            case element(docImprint) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "docImprint1")
                else
                    fo:inline($config, ., "docImprint2", .)
            case element(docTitle) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "docTitle1")
                else
                    fo:block($config, ., "docTitle2", .)
            case element(epigraph) return
                fo:block($config, ., "epigraph", .)
            case element(ex) return
                fo:inline($config, ., "ex", .)
            case element(expan) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    fo:omit($config, ., "expan1")
                else
                    fo:inline($config, ., "expan2", .)
            case element(figDesc) return
                fo:inline($config, ., "figDesc", .)
            case element(figure) return
                if (head or @rendition='simple:display') then
                    fo:block($config, ., "figure1", .)
                else
                    fo:inline($config, ., "figure2", .)
            case element(floatingText) return
                fo:block($config, ., "floatingText", .)
            case element(foreign) return
                fo:inline($config, ., "foreign", .)
            case element(formula) return
                if (@rendition='simple:display') then
                    fo:block($config, ., "formula1", .)
                else
                    fo:inline($config, ., "formula2", .)
            case element(front) return
                fo:block($config, ., "front", .)
            case element(fw) return
                if (ancestor::p or ancestor::ab) then
                    fo:inline($config, ., "fw1", .)
                else
                    fo:block($config, ., "fw2", .)
            case element(g) return
                if (not(text())) then
                    fo:glyph($config, ., "g1", @ref)
                else
                    fo:inline($config, ., "g2", .)
            case element(gap) return
                if (desc) then
                    fo:inline($config, ., "gap1", desc)
                else
                    if (@extent) then
                        fo:inline($config, ., "gap2", @extent)
                    else
                        (: No function found for behavior: inline() :)
                        $config?apply($config, ./node())
            case element(graphic) return
                fo:graphic($config, ., "graphic", @url, @width, @height, @scale)
            case element(group) return
                fo:block($config, ., "group", .)
            case element(handShift) return
                fo:inline($config, ., "handShift", .)
            case element(head) return
                if (parent::figure) then
                    fo:block($config, ., "head1", .)
                else
                    if (parent::table) then
                        fo:block($config, ., "head2", .)
                    else
                        if (parent::lg) then
                            fo:block($config, ., "head3", .)
                        else
                            if (parent::list) then
                                fo:block($config, ., "head4", .)
                            else
                                if (parent::div) then
                                    fo:heading($config, ., "head5", ., @type, div)
                                else
                                    fo:block($config, ., "head6", .)
            case element(hi) return
                if (@rendition) then
                    fo:inline($config, ., fo:get-rendition(., "hi1"), .)
                else
                    if (not(@rendition)) then
                        fo:inline($config, ., "hi2", .)
                    else
                        $config?apply($config, ./node())
            case element(imprimatur) return
                fo:block($config, ., "imprimatur", .)
            case element(item) return
                if (parent::list[@rendition]) then
                    fo:listItem($config, ., "item1", .)
                else
                    if (not(parent::list[@rendition])) then
                        fo:listItem($config, ., "item2", .)
                    else
                        $config?apply($config, ./node())
            case element(l) return
                fo:block($config, ., fo:get-rendition(., "l"), .)
            case element(label) return
                fo:inline($config, ., "label", .)
            case element(lb) return
                if (ancestor::sp) then
                    fo:break($config, ., "lb1", 'line', @n)
                else
                    fo:omit($config, ., "lb2")
            case element(lg) return
                fo:block($config, ., "lg", .)
            case element(list) return
                if (@rendition) then
                    fo:list($config, ., fo:get-rendition(., "list1"), item)
                else
                    if (not(@rendition)) then
                        fo:list($config, ., "list2", item)
                    else
                        $config?apply($config, ./node())
            case element(listBibl) return
                fo:list($config, ., "listBibl", bibl)
            case element(measure) return
                fo:inline($config, ., "measure", .)
            case element(milestone) return
                fo:inline($config, ., "milestone", .)
            case element(name) return
                fo:inline($config, ., "name", .)
            case element(note) return
                if (@place) then
                    fo:note($config, ., "note1", ., @place)
                else
                    if (parent::div and not(@place)) then
                        fo:block($config, ., "note2", .)
                    else
                        if (not(@place)) then
                            fo:inline($config, ., "note3", .)
                        else
                            $config?apply($config, ./node())
            case element(num) return
                fo:inline($config, ., "num", .)
            case element(opener) return
                fo:block($config, ., "opener", .)
            case element(orig) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    (: Omit, if handled in parent choice. :)
                    fo:omit($config, ., "orig1")
                else
                    fo:inline($config, ., "orig2", .)
            case element(p) return
                fo:paragraph($config, ., fo:get-rendition(., "p"), .)
            case element(pb) return
                fo:break($config, ., "pb", 'page', @n)
            case element(pc) return
                fo:inline($config, ., "pc", .)
            case element(postscript) return
                fo:block($config, ., "postscript", .)
            case element(publisher) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "publisher")
                else
                    $config?apply($config, ./node())
            case element(pubPlace) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    fo:omit($config, ., "pubPlace")
                else
                    $config?apply($config, ./node())
            case element(q) return
                if (l) then
                    fo:block($config, ., fo:get-rendition(., "q1"), .)
                else
                    if (ancestor::p or ancestor::cell) then
                        fo:inline($config, ., fo:get-rendition(., "q2"), .)
                    else
                        fo:block($config, ., fo:get-rendition(., "q3"), .)
            case element(quote) return
                if (ancestor::p) then
                    (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                    fo:inline($config, ., fo:get-rendition(., "quote1"), .)
                else
                    (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                    fo:block($config, ., fo:get-rendition(., "quote2"), .)
            case element(ref) return
                if (not(@target)) then
                    fo:inline($config, ., "ref1", .)
                else
                    if (not(text())) then
                        fo:link($config, ., "ref2", @target, @target)
                    else
                        fo:link($config, ., "ref3", ., @target)
            case element(reg) return
                if (not(parent::choice)) then
                    fo:inline($config, ., "reg1", .)
                else
                    if (parent::choice and count(parent::*/*) gt 1) then
                        (: Omit, if handled in parent choice. :)
                        fo:omit($config, ., "reg2")
                    else
                        fo:inline($config, ., "reg3", .)
            case element(rhyme) return
                fo:inline($config, ., "rhyme", .)
            case element(role) return
                fo:block($config, ., "role", .)
            case element(roleDesc) return
                fo:block($config, ., "roleDesc", .)
            case element(row) return
                if (@role='label') then
                    fo:row($config, ., "row1", .)
                else
                    (: Insert table row. :)
                    fo:row($config, ., "row2", .)
            case element(rs) return
                fo:inline($config, ., "rs", .)
            case element(s) return
                fo:inline($config, ., "s", .)
            case element(salute) return
                if (parent::closer) then
                    fo:inline($config, ., "salute1", .)
                else
                    fo:block($config, ., "salute2", .)
            case element(seg) return
                fo:inline($config, ., "seg", .)
            case element(sic) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    fo:omit($config, ., "sic1")
                else
                    fo:inline($config, ., "sic2", .)
            case element(signed) return
                if (parent::closer) then
                    fo:block($config, ., "signed1", .)
                else
                    fo:inline($config, ., "signed2", .)
            case element(sp) return
                fo:block($config, ., "sp", .)
            case element(space) return
                fo:inline($config, ., "space", .)
            case element(speaker) return
                fo:block($config, ., "speaker", .)
            case element(spGrp) return
                fo:block($config, ., "spGrp", .)
            case element(stage) return
                fo:block($config, ., "stage", .)
            case element(subst) return
                fo:inline($config, ., "subst", .)
            case element(supplied) return
                if (parent::choice) then
                    fo:omit($config, ., "supplied1")
                else
                    if (@reason='damage') then
                        fo:inline($config, ., "supplied2", .)
                    else
                        if (@reason='illegible' or not(@reason)) then
                            fo:inline($config, ., "supplied3", .)
                        else
                            if (@reason='omitted') then
                                fo:inline($config, ., "supplied4", .)
                            else
                                fo:inline($config, ., "supplied5", .)
            case element(table) return
                fo:table($config, ., "table", .)
            case element(fileDesc) return
                fo:title($config, ., "fileDesc", titleStmt)
            case element(profileDesc) return
                fo:omit($config, ., "profileDesc")
            case element(revisionDesc) return
                fo:omit($config, ., "revisionDesc")
            case element(encodingDesc) return
                fo:omit($config, ., "encodingDesc")
            case element(teiHeader) return
                fo:metadata($config, ., "teiHeader", .)
            case element(TEI) return
                fo:document($config, ., "TEI", .)
            case element(text) return
                fo:body($config, ., "text", .)
            case element(time) return
                fo:inline($config, ., "time", .)
            case element(title) return
                if (parent::titleStmt/parent::fileDesc) then
                    (
                        if (preceding-sibling::title) then
                            fo:text($config, ., "title1", ' — ')
                        else
                            (),
                        fo:text($config, ., "title2", .)
                    )

                else
                    if (not(@level) and parent::bibl) then
                        fo:inline($config, ., "title1", .)
                    else
                        if (@level='m' or not(@level)) then
                            (
                                fo:inline($config, ., "title1", .),
                                if (ancestor::biblStruct or       ancestor::biblFull) then
                                    (: No function found for behavior: text(', ') :)
                                    $config?apply($config, ./node())
                                else
                                    ()
                            )

                        else
                            if (@level='s' or @level='j') then
                                (
                                    fo:inline($config, ., "title1", .),
                                    if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                        fo:text($config, ., "title2", ' ')
                                    else
                                        ()
                                )

                            else
                                if (@level='u' or @level='a') then
                                    (
                                        fo:inline($config, ., "title1", .),
                                        if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                            fo:text($config, ., "title2", '. ')
                                        else
                                            ()
                                    )

                                else
                                    fo:inline($config, ., "title2", .)
            case element(titlePage) return
                fo:block($config, ., "titlePage", .)
            case element(titlePart) return
                fo:block($config, ., "titlePart", .)
            case element(trailer) return
                fo:block($config, ., "trailer", .)
            case element(unclear) return
                fo:inline($config, ., "unclear", .)
            case element(w) return
                fo:inline($config, ., "w", .)
            case text() | xs:anyAtomicType return
                fo:escapeChars(.)
            default return 
                $config?apply($config, ./node())

    )

};

