(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/beamer.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/beamer/fo";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xi='http://www.w3.org/2001/XInclude';

declare namespace skos='http://www.w3.org/2004/02/skos/core#';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace fo="http://www.tei-c.org/tei-simple/xquery/functions/fo";

import module namespace ext-fo="http://www.tei-c.org/tei-simple/xquery/ext-fo" at "xmldb:exist:///db/apps/tei-publisher/modules/ext-fo.xql";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["fo","print"],
                "odd": "/db/apps/tei-publisher/odd/beamer.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    let $config := fo:init($config, $input)
    
    return (
        
        model:apply($config, $input)
    )
};

declare function model:apply($config as map(*), $input as node()*) {
    let $parameters := 
        if (exists($config?parameters)) then $config?parameters else map {}
    return
    $input !         (
            typeswitch(.)
                case element(text) return
                    (: tei_simplePrint.odd sets a font and margin on the text body. We don't want that. :)
                    fo:body($config, ., ("tei-text"), .)
                case element(ab) return
                    fo:paragraph($config, ., ("tei-ab"), .)
                case element(abbr) return
                    fo:inline($config, ., ("tei-abbr"), .)
                case element(actor) return
                    fo:inline($config, ., ("tei-actor"), .)
                case element(add) return
                    fo:inline($config, ., ("tei-add"), .)
                case element(address) return
                    fo:block($config, ., ("tei-address"), .)
                case element(addrLine) return
                    fo:block($config, ., ("tei-addrLine"), .)
                case element(am) return
                    fo:inline($config, ., ("tei-am"), .)
                case element(anchor) return
                    fo:anchor($config, ., ("tei-anchor"), ., @xml:id)
                case element(argument) return
                    fo:block($config, ., ("tei-argument"), .)
                case element(author) return
                    if (ancestor::teiHeader) then
                        fo:block($config, ., ("tei-author1"), .)
                    else
                        fo:inline($config, ., ("tei-author2"), .)
                case element(back) return
                    fo:block($config, ., ("tei-back"), .)
                case element(bibl) return
                    if (parent::listBibl) then
                        fo:listItem($config, ., ("tei-bibl1"), .)
                    else
                        fo:inline($config, ., ("tei-bibl2"), .)
                case element(biblScope) return
                    fo:inline($config, ., ("tei-biblScope"), .)
                case element(body) return
                    (
                        fo:index($config, ., ("tei-body1"), ., 'toc'),
                        fo:block($config, ., ("tei-body2"), .)
                    )

                case element(byline) return
                    fo:block($config, ., ("tei-byline"), .)
                case element(c) return
                    fo:inline($config, ., ("tei-c"), .)
                case element(castGroup) return
                    if (child::*) then
                        (: Insert list. :)
                        fo:list($config, ., ("tei-castGroup"), castItem|castGroup)
                    else
                        $config?apply($config, ./node())
                case element(castItem) return
                    (: Insert item, rendered as described in parent list rendition. :)
                    fo:listItem($config, ., ("tei-castItem"), .)
                case element(castList) return
                    if (child::*) then
                        fo:list($config, ., css:get-rendition(., ("tei-castList")), castItem)
                    else
                        $config?apply($config, ./node())
                case element(cb) return
                    fo:break($config, ., ("tei-cb"), ., 'column', @n)
                case element(cell) return
                    (: Insert table cell. :)
                    fo:cell($config, ., ("tei-cell"), ., ())
                case element(choice) return
                    if (sic and corr) then
                        fo:alternate($config, ., ("tei-choice4"), ., corr[1], sic[1])
                    else
                        if (abbr and expan) then
                            fo:alternate($config, ., ("tei-choice5"), ., expan[1], abbr[1])
                        else
                            if (orig and reg) then
                                fo:alternate($config, ., ("tei-choice6"), ., reg[1], orig[1])
                            else
                                $config?apply($config, ./node())
                case element(cit) return
                    if (child::quote and child::bibl) then
                        (: Insert citation :)
                        fo:cit($config, ., ("tei-cit"), ., ())
                    else
                        $config?apply($config, ./node())
                case element(closer) return
                    fo:block($config, ., ("tei-closer"), .)
                case element(code) return
                    fo:inline($config, ., ("tei-code"), .)
                case element(corr) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        (: simple inline, if in parent choice. :)
                        fo:inline($config, ., ("tei-corr1"), .)
                    else
                        fo:inline($config, ., ("tei-corr2"), .)
                case element(date) return
                    if (text()) then
                        fo:inline($config, ., ("tei-date1"), .)
                    else
                        if (@when and not(text())) then
                            fo:inline($config, ., ("tei-date2"), @when)
                        else
                            if (text()) then
                                fo:inline($config, ., ("tei-date4"), .)
                            else
                                $config?apply($config, ./node())
                case element(dateline) return
                    fo:block($config, ., ("tei-dateline"), .)
                case element(del) return
                    fo:inline($config, ., ("tei-del"), .)
                case element(desc) return
                    fo:inline($config, ., ("tei-desc"), .)
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
                                fo:section($config, ., ("tei-div4"), .)
                case element(docAuthor) return
                    fo:inline($config, ., ("tei-docAuthor"), .)
                case element(docDate) return
                    fo:inline($config, ., ("tei-docDate"), .)
                case element(docEdition) return
                    fo:inline($config, ., ("tei-docEdition"), .)
                case element(docImprint) return
                    fo:inline($config, ., ("tei-docImprint"), .)
                case element(docTitle) return
                    fo:block($config, ., css:get-rendition(., ("tei-docTitle")), .)
                case element(editor) return
                    if (ancestor::teiHeader) then
                        fo:omit($config, ., ("tei-editor1"), .)
                    else
                        fo:inline($config, ., ("tei-editor2"), .)
                case element(email) return
                    fo:inline($config, ., ("tei-email"), .)
                case element(epigraph) return
                    fo:block($config, ., ("tei-epigraph"), .)
                case element(ex) return
                    fo:inline($config, ., ("tei-ex"), .)
                case element(expan) return
                    fo:inline($config, ., ("tei-expan"), .)
                case element(figDesc) return
                    fo:inline($config, ., ("tei-figDesc"), .)
                case element(figure) return
                    if (head or @rendition='simple:display') then
                        fo:block($config, ., ("tei-figure1"), .)
                    else
                        (: Changed to not show a blue border around the figure :)
                        fo:inline($config, ., ("tei-figure2"), .)
                case element(floatingText) return
                    fo:block($config, ., ("tei-floatingText"), .)
                case element(foreign) return
                    fo:inline($config, ., ("tei-foreign"), .)
                case element(formula) return
                    if (@rendition='simple:display') then
                        fo:block($config, ., ("tei-formula1"), .)
                    else
                        fo:inline($config, ., ("tei-formula2"), .)
                case element(front) return
                    fo:block($config, ., ("tei-front"), .)
                case element(fw) return
                    if (ancestor::p or ancestor::ab) then
                        fo:inline($config, ., ("tei-fw1"), .)
                    else
                        fo:block($config, ., ("tei-fw2"), .)
                case element(g) return
                    if (not(text())) then
                        fo:glyph($config, ., ("tei-g1"), .)
                    else
                        fo:inline($config, ., ("tei-g2"), .)
                case element(gap) return
                    if (desc) then
                        fo:inline($config, ., ("tei-gap1"), .)
                    else
                        if (@extent) then
                            fo:inline($config, ., ("tei-gap2"), @extent)
                        else
                            fo:inline($config, ., ("tei-gap3"), .)
                case element(graphic) return
                    fo:graphic($config, ., ("tei-graphic"), ., @url, @width, @height, @scale, desc)
                case element(group) return
                    fo:block($config, ., ("tei-group"), .)
                case element(head) return
                    if (parent::div[@type='frame']) then
                        (: No function found for behavior: frametitle :)
                        $config?apply($config, ./node())
                    else
                        fo:heading($config, ., ("tei-head2"), .)
                case element(hi) return
                    (: No function found for behavior: alert :)
                    $config?apply($config, ./node())
                case element(imprimatur) return
                    fo:block($config, ., ("tei-imprimatur"), .)
                case element(item) return
                    fo:listItem($config, ., ("tei-item"), .)
                case element(l) return
                    fo:block($config, ., css:get-rendition(., ("tei-l")), .)
                case element(label) return
                    fo:inline($config, ., ("tei-label"), .)
                case element(lb) return
                    fo:break($config, ., css:get-rendition(., ("tei-lb")), ., 'line', @n)
                case element(lg) return
                    fo:block($config, ., ("tei-lg"), .)
                case element(list) return
                    if (@rendition) then
                        fo:list($config, ., css:get-rendition(., ("tei-list1")), item)
                    else
                        if (not(@rendition)) then
                            fo:list($config, ., ("tei-list2"), item)
                        else
                            $config?apply($config, ./node())
                case element(listBibl) return
                    if (bibl) then
                        fo:list($config, ., ("tei-listBibl1"), bibl)
                    else
                        fo:block($config, ., ("tei-listBibl2"), .)
                case element(measure) return
                    fo:inline($config, ., ("tei-measure"), .)
                case element(milestone) return
                    fo:inline($config, ., ("tei-milestone"), .)
                case element(name) return
                    fo:inline($config, ., ("tei-name"), .)
                case element(note) return
                    if (@place) then
                        fo:note($config, ., ("tei-note1"), ., @place, @n)
                    else
                        if (parent::div and not(@place)) then
                            fo:block($config, ., ("tei-note2"), .)
                        else
                            if (not(@place)) then
                                fo:inline($config, ., ("tei-note3"), .)
                            else
                                $config?apply($config, ./node())
                case element(num) return
                    fo:inline($config, ., ("tei-num"), .)
                case element(opener) return
                    fo:block($config, ., ("tei-opener"), .)
                case element(orig) return
                    fo:inline($config, ., ("tei-orig"), .)
                case element(p) return
                    fo:paragraph($config, ., css:get-rendition(., ("tei-p")), .)
                case element(pb) return
                    fo:break($config, ., css:get-rendition(., ("tei-pb")), ., 'page', (concat(if(@n) then concat(@n,' ') else '',if(@facs) then                   concat('@',@facs) else '')))
                case element(pc) return
                    fo:inline($config, ., ("tei-pc"), .)
                case element(postscript) return
                    fo:block($config, ., ("tei-postscript"), .)
                case element(publisher) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        fo:omit($config, ., ("tei-publisher"), .)
                    else
                        $config?apply($config, ./node())
                case element(pubPlace) return
                    if (ancestor::teiHeader) then
                        (: Omit if located in teiHeader. :)
                        fo:omit($config, ., ("tei-pubPlace"), .)
                    else
                        $config?apply($config, ./node())
                case element(q) return
                    if (l) then
                        fo:block($config, ., css:get-rendition(., ("tei-q1")), .)
                    else
                        if (ancestor::p or ancestor::cell) then
                            fo:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                        else
                            fo:block($config, ., css:get-rendition(., ("tei-q3")), .)
                case element(quote) return
                    if (ancestor::p) then
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        fo:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                    else
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        fo:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                case element(ref) return
                    if (not(@target)) then
                        fo:inline($config, ., ("tei-ref1"), .)
                    else
                        if (not(text())) then
                            fo:link($config, ., ("tei-ref2"), @target, ())
                        else
                            fo:link($config, ., ("tei-ref3"), ., ())
                case element(reg) return
                    fo:inline($config, ., ("tei-reg"), .)
                case element(relatedItem) return
                    fo:inline($config, ., ("tei-relatedItem"), .)
                case element(rhyme) return
                    fo:inline($config, ., ("tei-rhyme"), .)
                case element(role) return
                    fo:block($config, ., ("tei-role"), .)
                case element(roleDesc) return
                    fo:block($config, ., ("tei-roleDesc"), .)
                case element(row) return
                    if (@role='label') then
                        fo:row($config, ., ("tei-row1"), .)
                    else
                        (: Insert table row. :)
                        fo:row($config, ., ("tei-row2"), .)
                case element(rs) return
                    fo:inline($config, ., ("tei-rs"), .)
                case element(s) return
                    fo:inline($config, ., ("tei-s"), .)
                case element(salute) return
                    if (parent::closer) then
                        fo:inline($config, ., ("tei-salute1"), .)
                    else
                        fo:block($config, ., ("tei-salute2"), .)
                case element(seg) return
                    fo:inline($config, ., css:get-rendition(., ("tei-seg")), .)
                case element(sic) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        fo:inline($config, ., ("tei-sic1"), .)
                    else
                        fo:inline($config, ., ("tei-sic2"), .)
                case element(signed) return
                    if (parent::closer) then
                        fo:block($config, ., ("tei-signed1"), .)
                    else
                        fo:inline($config, ., ("tei-signed2"), .)
                case element(sp) return
                    fo:block($config, ., ("tei-sp"), .)
                case element(speaker) return
                    fo:block($config, ., ("tei-speaker"), .)
                case element(spGrp) return
                    fo:block($config, ., ("tei-spGrp"), .)
                case element(stage) return
                    fo:block($config, ., ("tei-stage"), .)
                case element(subst) return
                    fo:inline($config, ., ("tei-subst"), .)
                case element(supplied) return
                    if (parent::choice) then
                        fo:inline($config, ., ("tei-supplied1"), .)
                    else
                        if (@reason='damage') then
                            fo:inline($config, ., ("tei-supplied2"), .)
                        else
                            if (@reason='illegible' or not(@reason)) then
                                fo:inline($config, ., ("tei-supplied3"), .)
                            else
                                if (@reason='omitted') then
                                    fo:inline($config, ., ("tei-supplied4"), .)
                                else
                                    fo:inline($config, ., ("tei-supplied5"), .)
                case element(table) return
                    fo:table($config, ., ("tei-table"), .)
                case element(fileDesc) return
                    if ($parameters?header='short') then
                        (
                            fo:block($config, ., ("tei-fileDesc1", "header-short"), titleStmt),
                            fo:block($config, ., ("tei-fileDesc2", "header-short"), editionStmt),
                            fo:block($config, ., ("tei-fileDesc3", "header-short"), publicationStmt)
                        )

                    else
                        fo:title($config, ., ("tei-fileDesc4"), titleStmt)
                case element(profileDesc) return
                    fo:omit($config, ., ("tei-profileDesc"), .)
                case element(revisionDesc) return
                    fo:omit($config, ., ("tei-revisionDesc"), .)
                case element(encodingDesc) return
                    fo:omit($config, ., ("tei-encodingDesc"), .)
                case element(teiHeader) return
                    fo:omit($config, ., ("tei-teiHeader2"), .)
                case element(TEI) return
                    fo:document($config, ., ("tei-TEI"), .)
                case element(text) return
                    (: tei_simplePrint.odd sets a font and margin on the text body. We don't want that. :)
                    fo:body($config, ., ("tei-text"), .)
                case element(time) return
                    fo:inline($config, ., ("tei-time"), .)
                case element(title) return
                    if ($parameters?header='short') then
                        fo:heading($config, ., ("tei-title1"), .)
                    else
                        if (parent::titleStmt/parent::fileDesc) then
                            (
                                if (preceding-sibling::title) then
                                    fo:text($config, ., ("tei-title2"), ' — ')
                                else
                                    (),
                                fo:inline($config, ., ("tei-title3"), .)
                            )

                        else
                            if (not(@level) and parent::bibl) then
                                fo:inline($config, ., ("tei-title4"), .)
                            else
                                if (@level='m' or not(@level)) then
                                    (
                                        fo:inline($config, ., ("tei-title5"), .),
                                        if (ancestor::biblFull) then
                                            fo:text($config, ., ("tei-title6"), ', ')
                                        else
                                            ()
                                    )

                                else
                                    if (@level='s' or @level='j') then
                                        (
                                            fo:inline($config, ., ("tei-title7"), .),
                                            if (following-sibling::* and     (  ancestor::biblFull)) then
                                                fo:text($config, ., ("tei-title8"), ', ')
                                            else
                                                ()
                                        )

                                    else
                                        if (@level='u' or @level='a') then
                                            (
                                                fo:inline($config, ., ("tei-title9"), .),
                                                if (following-sibling::* and     (    ancestor::biblFull)) then
                                                    fo:text($config, ., ("tei-title10"), '. ')
                                                else
                                                    ()
                                            )

                                        else
                                            fo:inline($config, ., ("tei-title11"), .)
                case element(titlePage) return
                    fo:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                case element(titlePart) return
                    fo:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                case element(trailer) return
                    fo:block($config, ., ("tei-trailer"), .)
                case element(unclear) return
                    fo:inline($config, ., ("tei-unclear"), .)
                case element(w) return
                    fo:inline($config, ., ("tei-w"), .)
                case element(titleStmt) return
                    fo:heading($config, ., ("tei-titleStmt2"), .)
                case element(publicationStmt) return
                    fo:omit($config, ., ("tei-publicationStmt2"), .)
                case element(licence) return
                    fo:omit($config, ., ("tei-licence2"), .)
                case element(edition) return
                    if (ancestor::teiHeader) then
                        fo:block($config, ., ("tei-edition"), .)
                    else
                        $config?apply($config, ./node())
                case element() return
                    if (namespace-uri(.) = 'http://www.tei-c.org/ns/1.0') then
                        $config?apply($config, ./node())
                    else
                        .
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

