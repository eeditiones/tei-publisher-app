(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-simple/odd/compiled/beamer.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/tei-simple/models/beamer.odd";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/css.xql";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions" at "xmldb:exist://embedded-eXist-server/db/apps/tei-simple/content/html-functions.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": ["web"],
                "odd": "/db/apps/tei-simple/odd/compiled/beamer.odd",
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
                    html:inline($config, ., ("tei-abbr"), .)
                case element(add) return
                    html:inline($config, ., ("tei-add"), .)
                case element(address) return
                    html:block($config, ., ("tei-address"), .)
                case element(addrLine) return
                    html:block($config, ., ("tei-addrLine"), .)
                case element(author) return
                    if (ancestor::teiHeader) then
                        html:omit($config, ., ("tei-author1"), .)
                    else
                        html:inline($config, ., ("tei-author2"), .)
                case element(bibl) return
                    if (parent::listBibl) then
                        html:listItem($config, ., ("tei-bibl1"), .)
                    else
                        html:inline($config, ., ("tei-bibl2"), .)
                case element(cb) return
                    html:break($config, ., ("tei-cb"), ., 'column', @n)
                case element(choice) return
                    if (sic and corr) then
                        html:alternate($config, ., ("tei-choice4"), ., corr[1], sic[1])
                    else
                        if (abbr and expan) then
                            html:alternate($config, ., ("tei-choice5"), ., expan[1], abbr[1])
                        else
                            if (orig and reg) then
                                html:alternate($config, ., ("tei-choice6"), ., reg[1], orig[1])
                            else
                                $config?apply($config, ./node())
                case element(cit) return
                    if (child::quote and child::bibl) then
                        (: Insert citation :)
                        html:cit($config, ., ("tei-cit"), .)
                    else
                        $config?apply($config, ./node())
                case element(corr) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        (: simple inline, if in parent choice. :)
                        html:inline($config, ., ("tei-corr1"), .)
                    else
                        html:inline($config, ., ("tei-corr2"), .)
                case element(date) return
                    if (@when) then
                        html:alternate($config, ., ("tei-date3"), ., ., @when)
                    else
                        if (text()) then
                            html:inline($config, ., ("tei-date4"), .)
                        else
                            $config?apply($config, ./node())
                case element(del) return
                    html:inline($config, ., ("tei-del"), .)
                case element(desc) return
                    html:inline($config, ., ("tei-desc"), .)
                case element(expan) return
                    html:inline($config, ., ("tei-expan"), .)
                case element(foreign) return
                    html:inline($config, ., ("tei-foreign"), .)
                case element(gap) return
                    if (desc) then
                        html:inline($config, ., ("tei-gap1"), .)
                    else
                        if (@extent) then
                            html:inline($config, ., ("tei-gap2"), @extent)
                        else
                            html:inline($config, ., ("tei-gap3"), .)
                case element(graphic) return
                    html:graphic($config, ., ("tei-graphic"), ., @url, @width, @height, @scale, desc)
                case element(head) return
                    if (parent::div[@type='frame']) then
                        (: No function found for behavior: frametitle :)
                        $config?apply($config, ./node())
                    else
                        html:heading($config, ., ("tei-head2"), .)
                case element(hi) return
                    (: No function found for behavior: alert :)
                    $config?apply($config, ./node())
                case element(item) return
                    html:listItem($config, ., ("tei-item"), .)
                case element(l) return
                    html:block($config, ., css:get-rendition(., ("tei-l")), .)
                case element(label) return
                    html:inline($config, ., ("tei-label"), .)
                case element(lb) return
                    html:break($config, ., css:get-rendition(., ("tei-lb")), ., 'line', @n)
                case element(lg) return
                    html:block($config, ., ("tei-lg"), .)
                case element(list) return
                    if (@rendition) then
                        html:list($config, ., css:get-rendition(., ("tei-list1")), item)
                    else
                        if (not(@rendition)) then
                            html:list($config, ., ("tei-list2"), item)
                        else
                            $config?apply($config, ./node())
                case element(listBibl) return
                    if (bibl) then
                        html:list($config, ., ("tei-listBibl1"), bibl)
                    else
                        html:block($config, ., ("tei-listBibl2"), .)
                case element(measure) return
                    html:inline($config, ., ("tei-measure"), .)
                case element(milestone) return
                    html:inline($config, ., ("tei-milestone"), .)
                case element(name) return
                    html:inline($config, ., ("tei-name"), .)
                case element(note) return
                    if (@place) then
                        html:note($config, ., ("tei-note1"), ., @place, @n)
                    else
                        if (parent::div and not(@place)) then
                            html:block($config, ., ("tei-note2"), .)
                        else
                            if (not(@place)) then
                                html:inline($config, ., ("tei-note3"), .)
                            else
                                $config?apply($config, ./node())
                case element(num) return
                    html:inline($config, ., ("tei-num"), .)
                case element(orig) return
                    html:inline($config, ., ("tei-orig"), .)
                case element(p) return
                    html:paragraph($config, ., css:get-rendition(., ("tei-p")), .)
                case element(pb) return
                    html:break($config, ., css:get-rendition(., ("tei-pb")), ., 'page', (concat(if(@n) then     concat(@n,' ') else '',if(@facs) then     concat('@',@facs) else '')))
                case element(publisher) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-publisher"), .)
                    else
                        $config?apply($config, ./node())
                case element(pubPlace) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-pubPlace"), .)
                    else
                        $config?apply($config, ./node())
                case element(q) return
                    if (l) then
                        html:block($config, ., css:get-rendition(., ("tei-q1")), .)
                    else
                        if (ancestor::p or ancestor::cell) then
                            html:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                        else
                            html:block($config, ., css:get-rendition(., ("tei-q3")), .)
                case element(quote) return
                    if (ancestor::p) then
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        html:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                    else
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        html:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                case element(ref) return
                    if (not(@target)) then
                        html:inline($config, ., ("tei-ref1"), .)
                    else
                        if (not(text())) then
                            html:link($config, ., ("tei-ref2"), @target, @target)
                        else
                            html:link($config, ., ("tei-ref3"), ., @target)
                case element(reg) return
                    html:inline($config, ., ("tei-reg"), .)
                case element(rs) return
                    html:inline($config, ., ("tei-rs"), .)
                case element(sic) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        html:inline($config, ., ("tei-sic1"), .)
                    else
                        html:inline($config, ., ("tei-sic2"), .)
                case element(sp) return
                    html:block($config, ., ("tei-sp"), .)
                case element(speaker) return
                    html:block($config, ., ("tei-speaker"), .)
                case element(stage) return
                    html:block($config, ., ("tei-stage"), .)
                case element(time) return
                    html:inline($config, ., ("tei-time"), .)
                case element(title) return
                    if (parent::titleStmt/parent::fileDesc) then
                        (
                            if (preceding-sibling::title) then
                                html:text($config, ., ("tei-title1"), ' — ')
                            else
                                (),
                            html:inline($config, ., ("tei-title2"), .)
                        )

                    else
                        if (not(@level) and parent::bibl) then
                            html:inline($config, ., ("tei-title1"), .)
                        else
                            if (@level='m' or not(@level)) then
                                (
                                    html:inline($config, ., ("tei-title1"), .),
                                    if (ancestor::biblStruct or       ancestor::biblFull) then
                                        html:text($config, ., ("tei-title2"), ', ')
                                    else
                                        ()
                                )

                            else
                                if (@level='s' or @level='j') then
                                    (
                                        html:inline($config, ., ("tei-title1"), .),
                                        if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                            html:text($config, ., ("tei-title2"), ', ')
                                        else
                                            ()
                                    )

                                else
                                    if (@level='u' or @level='a') then
                                        (
                                            html:inline($config, ., ("tei-title1"), .),
                                            if (following-sibling::* and     (ancestor::biblStruct  or     ancestor::biblFull)) then
                                                html:text($config, ., ("tei-title2"), '. ')
                                            else
                                                ()
                                        )

                                    else
                                        html:inline($config, ., ("tei-title2"), .)
                case element(unclear) return
                    html:inline($config, ., ("tei-unclear"), .)
                case element(fileDesc) return
                    html:title($config, ., ("tei-fileDesc"), titleStmt)
                case element(encodingDesc) return
                    html:omit($config, ., ("tei-encodingDesc"), .)
                case element(profileDesc) return
                    html:omit($config, ., ("tei-profileDesc"), .)
                case element(revisionDesc) return
                    html:omit($config, ., ("tei-revisionDesc"), .)
                case element(teiHeader) return
                    html:metadata($config, ., ("tei-teiHeader"), .)
                case element(g) return
                    if (not(text())) then
                        html:glyph($config, ., ("tei-g1"), @ref)
                    else
                        html:inline($config, ., ("tei-g2"), .)
                case element(addSpan) return
                    html:anchor($config, ., ("tei-addSpan"), ., @xml:id)
                case element(am) return
                    html:inline($config, ., ("tei-am"), .)
                case element(ex) return
                    html:inline($config, ., ("tei-ex"), .)
                case element(fw) return
                    if (ancestor::p or ancestor::ab) then
                        html:inline($config, ., ("tei-fw1"), .)
                    else
                        html:block($config, ., ("tei-fw2"), .)
                case element(handShift) return
                    html:inline($config, ., ("tei-handShift"), .)
                case element(space) return
                    html:inline($config, ., ("tei-space"), .)
                case element(subst) return
                    html:inline($config, ., ("tei-subst"), .)
                case element(supplied) return
                    if (parent::choice) then
                        html:inline($config, ., ("tei-supplied1"), .)
                    else
                        if (@reason='damage') then
                            html:inline($config, ., ("tei-supplied2"), .)
                        else
                            if (@reason='illegible' or not(@reason)) then
                                html:inline($config, ., ("tei-supplied3"), .)
                            else
                                if (@reason='omitted') then
                                    html:inline($config, ., ("tei-supplied4"), .)
                                else
                                    html:inline($config, ., ("tei-supplied5"), .)
                case element(c) return
                    html:inline($config, ., ("tei-c"), .)
                case element(pc) return
                    html:inline($config, ., ("tei-pc"), .)
                case element(s) return
                    html:inline($config, ., ("tei-s"), .)
                case element(w) return
                    html:inline($config, ., ("tei-w"), .)
                case element(ab) return
                    html:paragraph($config, ., ("tei-ab"), .)
                case element(anchor) return
                    html:anchor($config, ., ("tei-anchor"), ., @xml:id)
                case element(seg) return
                    html:inline($config, ., css:get-rendition(., ("tei-seg")), .)
                case element(actor) return
                    html:inline($config, ., ("tei-actor"), .)
                case element(castGroup) return
                    if (child::*) then
                        (: Insert list. :)
                        html:list($config, ., ("tei-castGroup"), castItem|castGroup)
                    else
                        $config?apply($config, ./node())
                case element(castItem) return
                    (: Insert item, rendered as described in parent list rendition. :)
                    html:listItem($config, ., ("tei-castItem"), .)
                case element(castList) return
                    if (child::*) then
                        html:list($config, ., css:get-rendition(., ("tei-castList")), castItem)
                    else
                        $config?apply($config, ./node())
                case element(role) return
                    html:block($config, ., ("tei-role"), .)
                case element(roleDesc) return
                    html:block($config, ., ("tei-roleDesc"), .)
                case element(spGrp) return
                    html:block($config, ., ("tei-spGrp"), .)
                case element(argument) return
                    html:block($config, ., ("tei-argument"), .)
                case element(back) return
                    html:block($config, ., ("tei-back"), .)
                case element(body) return
                    (
                        html:index($config, ., ("tei-body1"), 'toc', .),
                        html:block($config, ., ("tei-body2"), .)
                    )

                case element(byline) return
                    html:block($config, ., ("tei-byline"), .)
                case element(closer) return
                    html:block($config, ., ("tei-closer"), .)
                case element(dateline) return
                    html:block($config, ., ("tei-dateline"), .)
                case element(div) return
                    if (@type='block') then
                        (: No function found for behavior: beamer-block :)
                        $config?apply($config, ./node())
                    else
                        if (@type='alert') then
                            (: No function found for behavior: beamer-block :)
                            $config?apply($config, ./node())
                        else
                            if (@type='frame') then
                                (: No function found for behavior: frame :)
                                $config?apply($config, ./node())
                            else
                                html:section($config, ., ("tei-div4"), .)
                case element(docAuthor) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-docAuthor1"), .)
                    else
                        html:inline($config, ., ("tei-docAuthor2"), .)
                case element(docDate) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-docDate1"), .)
                    else
                        html:inline($config, ., ("tei-docDate2"), .)
                case element(docEdition) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-docEdition1"), .)
                    else
                        html:inline($config, ., ("tei-docEdition2"), .)
                case element(docImprint) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-docImprint1"), .)
                    else
                        html:inline($config, ., ("tei-docImprint2"), .)
                case element(docTitle) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        html:omit($config, ., ("tei-docTitle1"), .)
                    else
                        html:block($config, ., css:get-rendition(., ("tei-docTitle2")), .)
                case element(epigraph) return
                    html:block($config, ., ("tei-epigraph"), .)
                case element(floatingText) return
                    html:block($config, ., ("tei-floatingText"), .)
                case element(front) return
                    html:block($config, ., ("tei-front"), .)
                case element(group) return
                    html:block($config, ., ("tei-group"), .)
                case element(imprimatur) return
                    html:block($config, ., ("tei-imprimatur"), .)
                case element(opener) return
                    html:block($config, ., ("tei-opener"), .)
                case element(postscript) return
                    html:block($config, ., ("tei-postscript"), .)
                case element(salute) return
                    if (parent::closer) then
                        html:inline($config, ., ("tei-salute1"), .)
                    else
                        html:block($config, ., ("tei-salute2"), .)
                case element(signed) return
                    if (parent::closer) then
                        html:block($config, ., ("tei-signed1"), .)
                    else
                        html:inline($config, ., ("tei-signed2"), .)
                case element(TEI) return
                    html:document($config, ., ("tei-TEI"), .)
                case element(text) return
                    html:body($config, ., ("tei-text"), .)
                case element(titlePage) return
                    html:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                case element(titlePart) return
                    html:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                case element(trailer) return
                    html:block($config, ., ("tei-trailer"), .)
                case element(cell) return
                    (: Insert table cell. :)
                    html:cell($config, ., ("tei-cell"), .)
                case element(figDesc) return
                    html:inline($config, ., ("tei-figDesc"), .)
                case element(figure) return
                    if (head or @rendition='simple:display') then
                        html:block($config, ., ("tei-figure1"), .)
                    else
                        html:inline($config, ., ("tei-figure2"), .)
                case element(formula) return
                    if (@rendition='simple:display') then
                        html:block($config, ., ("tei-formula1"), .)
                    else
                        html:inline($config, ., ("tei-formula2"), .)
                case element(row) return
                    if (@role='label') then
                        html:row($config, ., ("tei-row1"), .)
                    else
                        (: Insert table row. :)
                        html:row($config, ., ("tei-row2"), .)
                case element(table) return
                    html:table($config, ., ("tei-table"), .)
                case element(rhyme) return
                    html:inline($config, ., ("tei-rhyme"), .)
                case element(code) return
                    (: No function found for behavior: code :)
                    $config?apply($config, ./node())
                case element(exist:match) return
                    html:match($config, ., .)
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

