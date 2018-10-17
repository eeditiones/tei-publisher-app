(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/teipublisher.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/teipublisher/latex";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xi='http://www.w3.org/2001/XInclude';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:new(($options,
            map {
                "output": ["latex","print"],
                "odd": "/db/apps/tei-publisher/odd/teipublisher.odd",
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
                    case element(castItem) return
                        (: Insert item, rendered as described in parent list rendition. :)
                        latex:listItem($config, ., ("tei-castItem"), .)
                    case element(item) return
                        latex:listItem($config, ., ("tei-item"), .)
                    case element(teiHeader) return
                        latex:metadata($config, ., ("tei-teiHeader1"), .)
                    case element(figure) return
                        if (head or @rendition='simple:display') then
                            latex:block($config, ., ("tei-figure1"), .)
                        else
                            latex:inline($config, ., ("tei-figure2"), .)
                    case element(supplied) return
                        if (parent::choice) then
                            latex:inline($config, ., ("tei-supplied1"), .)
                        else
                            if (@reason='damage') then
                                latex:inline($config, ., ("tei-supplied2"), .)
                            else
                                if (@reason='illegible' or not(@reason)) then
                                    latex:inline($config, ., ("tei-supplied3"), .)
                                else
                                    if (@reason='omitted') then
                                        latex:inline($config, ., ("tei-supplied4"), .)
                                    else
                                        latex:inline($config, ., ("tei-supplied5"), .)
                    case element(milestone) return
                        latex:inline($config, ., ("tei-milestone"), .)
                    case element(label) return
                        latex:inline($config, ., ("tei-label"), .)
                    case element(signed) return
                        if (parent::closer) then
                            latex:block($config, ., ("tei-signed1"), .)
                        else
                            latex:inline($config, ., ("tei-signed2"), .)
                    case element(pb) return
                        latex:break($config, ., css:get-rendition(., ("tei-pb")), ., 'page', (concat(if(@n) then concat(@n,' ') else '',if(@facs) then                   concat('@',@facs) else '')))
                    case element(pc) return
                        latex:inline($config, ., ("tei-pc"), .)
                    case element(TEI) return
                        latex:document($config, ., ("tei-TEI"), .)
                    case element(anchor) return
                        latex:anchor($config, ., ("tei-anchor"), ., @xml:id)
                    case element(formula) return
                        if (@rendition='simple:display') then
                            latex:block($config, ., ("tei-formula1"), .)
                        else
                            latex:inline($config, ., ("tei-formula2"), .)
                    case element(choice) return
                        if (sic and corr) then
                            latex:alternate($config, ., ("tei-choice4"), ., corr[1], sic[1])
                        else
                            if (abbr and expan) then
                                latex:alternate($config, ., ("tei-choice5"), ., expan[1], abbr[1])
                            else
                                if (orig and reg) then
                                    latex:alternate($config, ., ("tei-choice6"), ., reg[1], orig[1])
                                else
                                    $config?apply($config, ./node())
                    case element(hi) return
                        if (@rendition) then
                            latex:inline($config, ., css:get-rendition(., ("tei-hi1")), .)
                        else
                            if (not(@rendition)) then
                                latex:inline($config, ., ("tei-hi2"), .)
                            else
                                $config?apply($config, ./node())
                    case element(note) return
                        if (@place) then
                            latex:note($config, ., ("tei-note1"), ., @place, @n)
                        else
                            if (parent::div and not(@place)) then
                                latex:block($config, ., ("tei-note2"), .)
                            else
                                if (not(@place)) then
                                    latex:inline($config, ., ("tei-note3"), .)
                                else
                                    $config?apply($config, ./node())
                    case element(code) return
                        latex:inline($config, ., ("tei-code"), .)
                    case element(dateline) return
                        latex:block($config, ., ("tei-dateline"), .)
                    case element(back) return
                        latex:block($config, ., ("tei-back"), .)
                    case element(del) return
                        latex:inline($config, ., ("tei-del"), .)
                    case element(trailer) return
                        latex:block($config, ., ("tei-trailer"), .)
                    case element(titlePart) return
                        latex:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                    case element(ab) return
                        latex:paragraph($config, ., ("tei-ab"), .)
                    case element(revisionDesc) return
                        latex:omit($config, ., ("tei-revisionDesc"), .)
                    case element(subst) return
                        latex:inline($config, ., ("tei-subst"), .)
                    case element(am) return
                        latex:inline($config, ., ("tei-am"), .)
                    case element(roleDesc) return
                        latex:block($config, ., ("tei-roleDesc"), .)
                    case element(orig) return
                        latex:inline($config, ., ("tei-orig"), .)
                    case element(opener) return
                        latex:block($config, ., ("tei-opener"), .)
                    case element(speaker) return
                        latex:block($config, ., ("tei-speaker"), .)
                    case element(publisher) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            latex:omit($config, ., ("tei-publisher"), .)
                        else
                            $config?apply($config, ./node())
                    case element(imprimatur) return
                        latex:block($config, ., ("tei-imprimatur"), .)
                    case element(rs) return
                        latex:inline($config, ., ("tei-rs"), .)
                    case element(figDesc) return
                        latex:inline($config, ., ("tei-figDesc"), .)
                    case element(foreign) return
                        latex:inline($config, ., ("tei-foreign"), .)
                    case element(fileDesc) return
                        if ($parameters?header='short') then
                            (
                                latex:block($config, ., ("tei-fileDesc1", "header-short"), titleStmt),
                                latex:block($config, ., ("tei-fileDesc2", "header-short"), editionStmt),
                                latex:block($config, ., ("tei-fileDesc3", "header-short"), publicationStmt)
                            )

                        else
                            latex:title($config, ., ("tei-fileDesc4"), titleStmt)
                    case element(seg) return
                        latex:inline($config, ., css:get-rendition(., ("tei-seg")), .)
                    case element(profileDesc) return
                        latex:omit($config, ., ("tei-profileDesc"), .)
                    case element(email) return
                        latex:inline($config, ., ("tei-email"), .)
                    case element(floatingText) return
                        latex:block($config, ., ("tei-floatingText"), .)
                    case element(text) return
                        latex:body($config, ., ("tei-text"), .)
                    case element(sp) return
                        latex:block($config, ., ("tei-sp"), .)
                    case element(table) return
                        latex:table($config, ., ("tei-table"), ., map {})
                    case element(abbr) return
                        latex:inline($config, ., ("tei-abbr"), .)
                    case element(group) return
                        latex:block($config, ., ("tei-group"), .)
                    case element(cb) return
                        latex:break($config, ., ("tei-cb"), ., 'column', @n)
                    case element(editor) return
                        if (ancestor::teiHeader) then
                            latex:omit($config, ., ("tei-editor1"), .)
                        else
                            latex:inline($config, ., ("tei-editor2"), .)
                    case element(listBibl) return
                        if (bibl) then
                            latex:list($config, ., ("tei-listBibl1"), bibl)
                        else
                            latex:block($config, ., ("tei-listBibl2"), .)
                    case element(c) return
                        latex:inline($config, ., ("tei-c"), .)
                    case element(address) return
                        latex:block($config, ., ("tei-address"), .)
                    case element(g) return
                        if (not(text())) then
                            latex:glyph($config, ., ("tei-g1"), .)
                        else
                            latex:inline($config, ., ("tei-g2"), .)
                    case element(author) return
                        if (ancestor::teiHeader) then
                            latex:block($config, ., ("tei-author1"), .)
                        else
                            latex:inline($config, ., ("tei-author2"), .)
                    case element(castList) return
                        if (child::*) then
                            latex:list($config, ., css:get-rendition(., ("tei-castList")), castItem)
                        else
                            $config?apply($config, ./node())
                    case element(l) return
                        latex:block($config, ., css:get-rendition(., ("tei-l")), .)
                    case element(closer) return
                        latex:block($config, ., ("tei-closer"), .)
                    case element(rhyme) return
                        latex:inline($config, ., ("tei-rhyme"), .)
                    case element(p) return
                        latex:paragraph($config, ., css:get-rendition(., ("tei-p")), .)
                    case element(list) return
                        if (@rendition) then
                            latex:list($config, ., css:get-rendition(., ("tei-list1")), item)
                        else
                            if (not(@rendition)) then
                                latex:list($config, ., ("tei-list2"), item)
                            else
                                $config?apply($config, ./node())
                    case element(q) return
                        if (l) then
                            latex:block($config, ., css:get-rendition(., ("tei-q1")), .)
                        else
                            if (ancestor::p or ancestor::cell) then
                                latex:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                            else
                                latex:block($config, ., css:get-rendition(., ("tei-q3")), .)
                    case element(measure) return
                        latex:inline($config, ., ("tei-measure"), .)
                    case element(epigraph) return
                        latex:block($config, ., ("tei-epigraph"), .)
                    case element(actor) return
                        latex:inline($config, ., ("tei-actor"), .)
                    case element(s) return
                        latex:inline($config, ., ("tei-s"), .)
                    case element(lb) return
                        latex:break($config, ., css:get-rendition(., ("tei-lb")), ., 'line', @n)
                    case element(docTitle) return
                        latex:block($config, ., css:get-rendition(., ("tei-docTitle")), .)
                    case element(w) return
                        latex:inline($config, ., ("tei-w"), .)
                    case element(titlePage) return
                        latex:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                    case element(stage) return
                        latex:block($config, ., ("tei-stage"), .)
                    case element(name) return
                        latex:inline($config, ., ("tei-name"), .)
                    case element(lg) return
                        latex:block($config, ., ("tei-lg"), .)
                    case element(front) return
                        latex:block($config, ., ("tei-front"), .)
                    case element(desc) return
                        latex:inline($config, ., ("tei-desc"), .)
                    case element(biblScope) return
                        latex:inline($config, ., ("tei-biblScope"), .)
                    case element(role) return
                        latex:block($config, ., ("tei-role"), .)
                    case element(num) return
                        latex:inline($config, ., ("tei-num"), .)
                    case element(docEdition) return
                        latex:inline($config, ., ("tei-docEdition"), .)
                    case element(postscript) return
                        latex:block($config, ., ("tei-postscript"), .)
                    case element(docImprint) return
                        latex:inline($config, ., ("tei-docImprint"), .)
                    case element(relatedItem) return
                        latex:inline($config, ., ("tei-relatedItem"), .)
                    case element(cell) return
                        (: Insert table cell. :)
                        latex:cell($config, ., ("tei-cell"), ., ())
                    case element(div) return
                        if (@type='title_page') then
                            latex:block($config, ., ("tei-div1"), .)
                        else
                            if (parent::body or parent::front or parent::back) then
                                latex:section($config, ., ("tei-div2"), .)
                            else
                                latex:block($config, ., ("tei-div3"), .)
                    case element(reg) return
                        latex:inline($config, ., ("tei-reg"), .)
                    case element(graphic) return
                        latex:graphic($config, ., ("tei-graphic"), ., @url, @width, @height, @scale, desc)
                    case element(ref) return
                        if (not(@target)) then
                            latex:inline($config, ., ("tei-ref1"), .)
                        else
                            if (not(text())) then
                                latex:link($config, ., ("tei-ref2"), @target, ())
                            else
                                latex:link($config, ., ("tei-ref3"), ., ())
                    case element(pubPlace) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            latex:omit($config, ., ("tei-pubPlace"), .)
                        else
                            $config?apply($config, ./node())
                    case element(add) return
                        latex:inline($config, ., ("tei-add"), .)
                    case element(docDate) return
                        latex:inline($config, ., ("tei-docDate"), .)
                    case element(head) return
                        if ($parameters?header='short') then
                            latex:inline($config, ., ("tei-head1"), replace(string-join(.//text()[not(parent::ref)]), '^(.*?)[^\w]*$', '$1'))
                        else
                            if (parent::figure) then
                                latex:block($config, ., ("tei-head2"), .)
                            else
                                if (parent::table) then
                                    latex:block($config, ., ("tei-head3"), .)
                                else
                                    if (parent::lg) then
                                        latex:block($config, ., ("tei-head4"), .)
                                    else
                                        if (parent::list) then
                                            latex:block($config, ., ("tei-head5"), .)
                                        else
                                            if (parent::div) then
                                                latex:heading($config, ., ("tei-head6"), .)
                                            else
                                                latex:block($config, ., ("tei-head7"), .)
                    case element(ex) return
                        latex:inline($config, ., ("tei-ex"), .)
                    case element(time) return
                        latex:inline($config, ., ("tei-time"), .)
                    case element(castGroup) return
                        if (child::*) then
                            (: Insert list. :)
                            latex:list($config, ., ("tei-castGroup"), castItem|castGroup)
                        else
                            $config?apply($config, ./node())
                    case element(bibl) return
                        if (parent::listBibl) then
                            latex:listItem($config, ., ("tei-bibl1"), .)
                        else
                            latex:inline($config, ., ("tei-bibl2"), .)
                    case element(unclear) return
                        latex:inline($config, ., ("tei-unclear"), .)
                    case element(salute) return
                        if (parent::closer) then
                            latex:inline($config, ., ("tei-salute1"), .)
                        else
                            latex:block($config, ., ("tei-salute2"), .)
                    case element(title) return
                        if ($parameters?header='short') then
                            latex:heading($config, ., ("tei-title1"), .)
                        else
                            if (parent::titleStmt/parent::fileDesc) then
                                (
                                    if (preceding-sibling::title) then
                                        latex:text($config, ., ("tei-title2"), ' — ')
                                    else
                                        (),
                                    latex:inline($config, ., ("tei-title3"), .)
                                )

                            else
                                if (not(@level) and parent::bibl) then
                                    latex:inline($config, ., ("tei-title4"), .)
                                else
                                    if (@level='m' or not(@level)) then
                                        (
                                            latex:inline($config, ., ("tei-title5"), .),
                                            if (ancestor::biblFull) then
                                                latex:text($config, ., ("tei-title6"), ', ')
                                            else
                                                ()
                                        )

                                    else
                                        if (@level='s' or @level='j') then
                                            (
                                                latex:inline($config, ., ("tei-title7"), .),
                                                if (following-sibling::* and     (  ancestor::biblFull)) then
                                                    latex:text($config, ., ("tei-title8"), ', ')
                                                else
                                                    ()
                                            )

                                        else
                                            if (@level='u' or @level='a') then
                                                (
                                                    latex:inline($config, ., ("tei-title9"), .),
                                                    if (following-sibling::* and     (    ancestor::biblFull)) then
                                                        latex:text($config, ., ("tei-title10"), '. ')
                                                    else
                                                        ()
                                                )

                                            else
                                                latex:inline($config, ., ("tei-title11"), .)
                    case element(date) return
                        if (text()) then
                            latex:inline($config, ., ("tei-date1"), .)
                        else
                            if (@when and not(text())) then
                                latex:inline($config, ., ("tei-date2"), @when)
                            else
                                if (text()) then
                                    latex:inline($config, ., ("tei-date4"), .)
                                else
                                    $config?apply($config, ./node())
                    case element(argument) return
                        latex:block($config, ., ("tei-argument"), .)
                    case element(corr) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            (: simple inline, if in parent choice. :)
                            latex:inline($config, ., ("tei-corr1"), .)
                        else
                            latex:inline($config, ., ("tei-corr2"), .)
                    case element(cit) return
                        if (child::quote and child::bibl) then
                            (: Insert citation :)
                            latex:cit($config, ., ("tei-cit"), ., ())
                        else
                            $config?apply($config, ./node())
                    case element(sic) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            latex:inline($config, ., ("tei-sic1"), .)
                        else
                            latex:inline($config, ., ("tei-sic2"), .)
                    case element(expan) return
                        latex:inline($config, ., ("tei-expan"), .)
                    case element(spGrp) return
                        latex:block($config, ., ("tei-spGrp"), .)
                    case element(body) return
                        (
                            latex:index($config, ., ("tei-body1"), ., 'toc'),
                            latex:block($config, ., ("tei-body2"), .)
                        )

                    case element(fw) return
                        if (ancestor::p or ancestor::ab) then
                            latex:inline($config, ., ("tei-fw1"), .)
                        else
                            latex:block($config, ., ("tei-fw2"), .)
                    case element(encodingDesc) return
                        latex:omit($config, ., ("tei-encodingDesc"), .)
                    case element(quote) return
                        if (ancestor::p) then
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            latex:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                        else
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            latex:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                    case element(gap) return
                        if (desc) then
                            latex:inline($config, ., ("tei-gap1"), .)
                        else
                            if (@extent) then
                                latex:inline($config, ., ("tei-gap2"), @extent)
                            else
                                latex:inline($config, ., ("tei-gap3"), .)
                    case element(addrLine) return
                        latex:block($config, ., ("tei-addrLine"), .)
                    case element(row) return
                        if (@role='label') then
                            latex:row($config, ., ("tei-row1"), .)
                        else
                            (: Insert table row. :)
                            latex:row($config, ., ("tei-row2"), .)
                    case element(docAuthor) return
                        latex:inline($config, ., ("tei-docAuthor"), .)
                    case element(byline) return
                        latex:block($config, ., ("tei-byline"), .)
                    case element(titleStmt) return
                        (: No function found for behavior: meta :)
                        $config?apply($config, ./node())
                    case element(publicationStmt) return
                        latex:omit($config, ., ("tei-publicationStmt2"), .)
                    case element(licence) return
                        latex:omit($config, ., ("tei-licence2"), .)
                    case element(edition) return
                        if (ancestor::teiHeader) then
                            latex:block($config, ., ("tei-edition"), .)
                        else
                            $config?apply($config, ./node())
                    case element() return
                        if (namespace-uri(.) = 'http://www.tei-c.org/ns/1.0') then
                            $config?apply($config, ./node())
                        else
                            .
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

