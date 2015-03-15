(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-simple/odd/teisimple.odd
 :)
xquery version "3.0";

module namespace model="http://www.tei-c.org/tei-simple/models/teisimple.odd";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions" at "html-functions.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
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
                pmf:paragraph($config, ., "ab", .)
            case element(abbr) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    pmf:omit($config, ., "abbr1")
                else
                    pmf:inline($config, ., "abbr2", .)
            case element(actor) return
                pmf:inline($config, ., "actor", .)
            case element(add) return
                pmf:inline($config, ., "add", .)
            case element(address) return
                pmf:block($config, ., "address", .)
            case element(addrLine) return
                pmf:block($config, ., "addrLine", .)
            case element(addSpan) return
                pmf:anchor($config, ., "addSpan", @xml:id)
            case element(am) return
                pmf:inline($config, ., "am", .)
            case element(anchor) return
                pmf:anchor($config, ., "anchor", @xml:id)
            case element(argument) return
                pmf:block($config, ., "argument", .)
            case element(author) return
                if (ancestor::teiHeader) then
                    pmf:omit($config, ., "author1")
                else
                    pmf:inline($config, ., "author2", .)
            case element(back) return
                pmf:block($config, ., "back", .)
            case element(bibl) return
                pmf:inline($config, ., "bibl", .)
            case element(body) return
                (
                    (: No function found for behavior: index(.,'toc') :)
                    $config?apply($config, ./node()),
                    pmf:block($config, ., "body2", .)
                )

            case element(byline) return
                pmf:block($config, ., "byline", .)
            case element(c) return
                pmf:inline($config, ., "c", .)
            case element(castGroup) return
                if (child::*) then
                    (: Insert list. :)
                    pmf:list($config, ., "castGroup", castItem|castGroup)
                else
                    $config?apply($config, ./node())
            case element(castItem) return
                (: Insert item, rendered as described in parent list rendition. :)
                pmf:listItem($config, ., "castItem", .)
            case element(castList) return
                if (child::*) then
                    pmf:list($config, ., pmf:get-rendition(., "castList"), castItem)
                else
                    $config?apply($config, ./node())
            case element(cb) return
                pmf:break($config, ., "cb", 'column', @n)
            case element(cell) return
                (: Insert table cell. :)
                pmf:cell($config, ., "cell", .)
            case element(choice) return
                if (sic and corr) then
                    pmf:alternate($config, ., "choice1", corr[1], sic[1])
                else
                    if (abbr and expan) then
                        pmf:alternate($config, ., "choice2", expan[1], abbr[1])
                    else
                        if (orig and reg) then
                            pmf:alternate($config, ., "choice3", reg[1], orig[1])
                        else
                            $config?apply($config, ./node())
            case element(cit) return
                if (child::quote and child::bibl) then
                    (: Insert cit. :)
                    pmf:cit($config, ., "cit", .)
                else
                    $config?apply($config, ./node())
            case element(closer) return
                pmf:block($config, ., "closer", .)
            case element(corr) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    (: Omit, if handled in parent choice. :)
                    pmf:omit($config, ., "corr1")
                else
                    pmf:inline($config, ., "corr2", .)
            case element(date) return
                if (@when) then
                    pmf:alternate($config, ., "date3", ., @when)
                else
                    if (text()) then
                        pmf:inline($config, ., "date4", .)
                    else
                        $config?apply($config, ./node())
            case element(dateline) return
                pmf:block($config, ., "dateline", .)
            case element(del) return
                pmf:inline($config, ., "del", .)
            case element(desc) return
                pmf:omit($config, ., "desc")
            case element(div) return
                if (@type='title_page') then
                    pmf:block($config, ., "div1", .)
                else
                    pmf:section($config, ., "div2", .)
            case element(docAuthor) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "docAuthor1")
                else
                    pmf:inline($config, ., "docAuthor2", .)
            case element(docDate) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "docDate1")
                else
                    pmf:inline($config, ., "docDate2", .)
            case element(docEdition) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "docEdition1")
                else
                    pmf:inline($config, ., "docEdition2", .)
            case element(docImprint) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "docImprint1")
                else
                    pmf:inline($config, ., "docImprint2", .)
            case element(docTitle) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "docTitle1")
                else
                    pmf:block($config, ., "docTitle2", .)
            case element(epigraph) return
                pmf:block($config, ., "epigraph", .)
            case element(ex) return
                pmf:inline($config, ., "ex", .)
            case element(expan) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    pmf:omit($config, ., "expan1")
                else
                    pmf:inline($config, ., "expan2", .)
            case element(figDesc) return
                pmf:inline($config, ., "figDesc", .)
            case element(figure) return
                if (head or @rendition='simple:display') then
                    pmf:block($config, ., "figure1", .)
                else
                    pmf:inline($config, ., "figure2", .)
            case element(floatingText) return
                pmf:block($config, ., "floatingText", .)
            case element(foreign) return
                pmf:inline($config, ., "foreign", .)
            case element(formula) return
                if (@rendition='simple:display') then
                    pmf:block($config, ., "formula1", .)
                else
                    pmf:inline($config, ., "formula2", .)
            case element(front) return
                pmf:block($config, ., "front", .)
            case element(fw) return
                if (ancestor::p or ancestor::ab) then
                    pmf:inline($config, ., "fw1", .)
                else
                    pmf:block($config, ., "fw2", .)
            case element(g) return
                if (not(text())) then
                    pmf:glyph($config, ., "g1", @ref)
                else
                    pmf:inline($config, ., "g2", .)
            case element(gap) return
                if (desc) then
                    pmf:inline($config, ., "gap1", desc)
                else
                    if (@extent) then
                        pmf:inline($config, ., "gap2", @extent)
                    else
                        (: No function found for behavior: inline() :)
                        $config?apply($config, ./node())
            case element(graphic) return
                pmf:graphic($config, ., "graphic", @url, @width, @height, @scale)
            case element(group) return
                pmf:block($config, ., "group", .)
            case element(handShift) return
                pmf:inline($config, ., "handShift", .)
            case element(head) return
                if (parent::figure) then
                    pmf:block($config, ., "head1", .)
                else
                    if (parent::table) then
                        pmf:block($config, ., "head2", .)
                    else
                        if (parent::lg) then
                            pmf:block($config, ., "head3", .)
                        else
                            if (parent::list) then
                                pmf:block($config, ., "head4", .)
                            else
                                if (parent::div) then
                                    pmf:heading($config, ., "head5", ., @type, div)
                                else
                                    pmf:block($config, ., "head6", .)
            case element(hi) return
                if (@rendition) then
                    pmf:inline($config, ., pmf:get-rendition(., "hi1"), .)
                else
                    if (not(@rendition)) then
                        pmf:inline($config, ., "hi2", .)
                    else
                        $config?apply($config, ./node())
            case element(imprimatur) return
                pmf:block($config, ., "imprimatur", .)
            case element(item) return
                if (parent::list[@rendition]) then
                    pmf:listItem($config, ., "item1", .)
                else
                    if (not(parent::list[@rendition])) then
                        pmf:listItem($config, ., "item2", .)
                    else
                        $config?apply($config, ./node())
            case element(l) return
                pmf:block($config, ., pmf:get-rendition(., "l"), .)
            case element(label) return
                pmf:inline($config, ., "label", .)
            case element(lb) return
                if (ancestor::sp) then
                    pmf:break($config, ., "lb1", 'line', @n)
                else
                    pmf:omit($config, ., "lb2")
            case element(lg) return
                pmf:block($config, ., "lg", .)
            case element(list) return
                if (@rendition) then
                    pmf:list($config, ., pmf:get-rendition(., "list1"), item)
                else
                    if (not(@rendition)) then
                        pmf:list($config, ., "list2", item)
                    else
                        $config?apply($config, ./node())
            case element(listBibl) return
                pmf:list($config, ., "listBibl", bibl)
            case element(measure) return
                pmf:inline($config, ., "measure", .)
            case element(milestone) return
                pmf:inline($config, ., "milestone", .)
            case element(name) return
                pmf:inline($config, ., "name", .)
            case element(note) return
                if (@place) then
                    (: No function found for behavior: note(.,@place) :)
                    $config?apply($config, ./node())
                else
                    if (parent::div and not(@place)) then
                        pmf:block($config, ., "note2", .)
                    else
                        if (not(@place)) then
                            pmf:inline($config, ., "note3", .)
                        else
                            $config?apply($config, ./node())
            case element(num) return
                pmf:inline($config, ., "num", .)
            case element(opener) return
                pmf:block($config, ., "opener", .)
            case element(orig) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    (: Omit, if handled in parent choice. :)
                    pmf:omit($config, ., "orig1")
                else
                    pmf:inline($config, ., "orig2", .)
            case element(p) return
                pmf:paragraph($config, ., pmf:get-rendition(., "p"), .)
            case element(pb) return
                pmf:break($config, ., "pb", 'page', @n)
            case element(pc) return
                pmf:inline($config, ., "pc", .)
            case element(postscript) return
                pmf:block($config, ., "postscript", .)
            case element(publisher) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "publisher")
                else
                    $config?apply($config, ./node())
            case element(pubPlace) return
                if (ancestor::teiHeader) then
                    (: Omit if located in teiHeader. :)
                    pmf:omit($config, ., "pubPlace")
                else
                    $config?apply($config, ./node())
            case element(q) return
                if (l) then
                    pmf:block($config, ., pmf:get-rendition(., "q1"), .)
                else
                    if (ancestor::p or ancestor::cell) then
                        pmf:inline($config, ., pmf:get-rendition(., "q2"), .)
                    else
                        pmf:block($config, ., pmf:get-rendition(., "q3"), .)
            case element(quote) return
                if (ancestor::p) then
                    (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                    pmf:inline($config, ., pmf:get-rendition(., "quote1"), .)
                else
                    (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                    pmf:block($config, ., pmf:get-rendition(., "quote2"), .)
            case element(ref) return
                if (not(@target)) then
                    pmf:inline($config, ., "ref1", .)
                else
                    if (not(text())) then
                        pmf:link($config, ., "ref2", @target, @target)
                    else
                        pmf:link($config, ., "ref3", ., @target)
            case element(reg) return
                if (not(parent::choice)) then
                    pmf:inline($config, ., "reg1", .)
                else
                    if (parent::choice and count(parent::*/*) gt 1) then
                        (: Omit, if handled in parent choice. :)
                        pmf:omit($config, ., "reg2")
                    else
                        pmf:inline($config, ., "reg3", .)
            case element(rhyme) return
                pmf:inline($config, ., "rhyme", .)
            case element(role) return
                pmf:block($config, ., "role", .)
            case element(roleDesc) return
                pmf:block($config, ., "roleDesc", .)
            case element(row) return
                if (@role='label') then
                    pmf:row($config, ., "row1", .)
                else
                    (: Insert table row. :)
                    pmf:row($config, ., "row2", .)
            case element(rs) return
                pmf:inline($config, ., "rs", .)
            case element(s) return
                pmf:inline($config, ., "s", .)
            case element(salute) return
                if (parent::closer) then
                    pmf:inline($config, ., "salute1", .)
                else
                    pmf:block($config, ., "salute2", .)
            case element(seg) return
                pmf:inline($config, ., "seg", .)
            case element(sic) return
                if (parent::choice and count(parent::*/*) gt 1) then
                    pmf:omit($config, ., "sic1")
                else
                    pmf:inline($config, ., "sic2", .)
            case element(signed) return
                if (parent::closer) then
                    pmf:block($config, ., "signed1", .)
                else
                    pmf:inline($config, ., "signed2", .)
            case element(sp) return
                pmf:block($config, ., "sp", .)
            case element(space) return
                pmf:inline($config, ., "space", .)
            case element(speaker) return
                pmf:block($config, ., "speaker", .)
            case element(spGrp) return
                pmf:block($config, ., "spGrp", .)
            case element(stage) return
                pmf:block($config, ., "stage", .)
            case element(subst) return
                pmf:inline($config, ., "subst", .)
            case element(supplied) return
                if (parent::choice) then
                    pmf:omit($config, ., "supplied1")
                else
                    if (@reason='damage') then
                        pmf:inline($config, ., "supplied2", .)
                    else
                        if (@reason='illegible' or not(@reason)) then
                            pmf:inline($config, ., "supplied3", .)
                        else
                            if (@reason='omitted') then
                                pmf:inline($config, ., "supplied4", .)
                            else
                                pmf:inline($config, ., "supplied5", .)
            case element(table) return
                pmf:table($config, ., "table", .)
            case element(fileDesc) return
                pmf:title($config, ., "fileDesc", titleStmt)
            case element(profileDesc) return
                pmf:omit($config, ., "profileDesc")
            case element(revisionDesc) return
                pmf:omit($config, ., "revisionDesc")
            case element(encodingDesc) return
                pmf:omit($config, ., "encodingDesc")
            case element(teiHeader) return
                pmf:metadata($config, ., "teiHeader", .)
            case element(TEI) return
                pmf:document($config, ., "TEI", .)
            case element(text) return
                pmf:body($config, ., "text", .)
            case element(time) return
                pmf:inline($config, ., "time", .)
            case element(title) return
                if (parent::titleStmt/parent::fileDesc) then
                    (
                        if (preceding-sibling::title) then
                            pmf:text($config, ., "title1", ' — ')
                        else
                            (),
                        pmf:text($config, ., "title2", .)
                    )

                else
                    if (not(@level) and parent::bibl) then
                        pmf:inline($config, ., "title1", .)
                    else
                        if (@level='m' or not(@level)) then
                            (
                                pmf:inline($config, ., "title1", .),
                                if (ancestor::biblStruct or       ancestor::biblFull) then
                                    (: No function found for behavior: text(', ') :)
                                    $config?apply($config, ./node())
                                else
                                    ()
                            )

                        else
                            if (@level='s' or @level='j') then
                                (
                                    pmf:inline($config, ., "title1", .),
                                    if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                        pmf:text($config, ., "title2", ' ')
                                    else
                                        ()
                                )

                            else
                                if (@level='u' or @level='a') then
                                    (
                                        pmf:inline($config, ., "title1", .),
                                        if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                            pmf:text($config, ., "title2", '. ')
                                        else
                                            ()
                                    )

                                else
                                    pmf:inline($config, ., "title2", .)
            case element(titlePage) return
                pmf:block($config, ., "titlePage", .)
            case element(titlePart) return
                pmf:block($config, ., "titlePart", .)
            case element(trailer) return
                pmf:block($config, ., "trailer", .)
            case element(unclear) return
                pmf:inline($config, ., "unclear", .)
            case element(w) return
                pmf:inline($config, ., "w", .)
            case text() | xs:anyAtomicType return
                .
            default return 
                $config?apply($config, ./node())

    )

};

