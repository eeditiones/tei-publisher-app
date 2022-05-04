(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/beamer.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/beamer/epub";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xi='http://www.w3.org/2001/XInclude';

declare namespace skos='http://www.w3.org/2004/02/skos/core#';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

import module namespace epub="http://www.tei-c.org/tei-simple/xquery/functions/epub";

(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["epub","web"],
                "odd": "/db/apps/tei-publisher/odd/beamer.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    
    return (
        html:prepare($config, $input),
    
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
                    html:body($config, ., ("tei-text"), .)
                case element(ab) return
                    html:paragraph($config, ., ("tei-ab"), .)
                case element(abbr) return
                    html:inline($config, ., ("tei-abbr"), .)
                case element(actor) return
                    html:inline($config, ., ("tei-actor"), .)
                case element(add) return
                    html:inline($config, ., ("tei-add"), .)
                case element(address) return
                    epub:block($config, ., ("tei-address"), .)
                case element(addrLine) return
                    epub:block($config, ., ("tei-addrLine"), .)
                case element(am) return
                    html:inline($config, ., ("tei-am"), .)
                case element(anchor) return
                    html:anchor($config, ., ("tei-anchor"), ., @xml:id)
                case element(argument) return
                    epub:block($config, ., ("tei-argument"), .)
                case element(author) return
                    if (ancestor::teiHeader) then
                        epub:block($config, ., ("tei-author1"), .)
                    else
                        html:inline($config, ., ("tei-author2"), .)
                case element(back) return
                    epub:block($config, ., ("tei-back"), .)
                case element(bibl) return
                    if (parent::listBibl) then
                        html:listItem($config, ., ("tei-bibl1"), .)
                    else
                        html:inline($config, ., ("tei-bibl2"), .)
                case element(biblScope) return
                    html:inline($config, ., ("tei-biblScope"), .)
                case element(body) return
                    (
                        html:index($config, ., ("tei-body1"), 'toc', .),
                        epub:block($config, ., ("tei-body2"), .)
                    )

                case element(byline) return
                    epub:block($config, ., ("tei-byline"), .)
                case element(c) return
                    html:inline($config, ., ("tei-c"), .)
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
                case element(cb) return
                    epub:break($config, ., ("tei-cb"), ., 'column', @n)
                case element(cell) return
                    (: Insert table cell. :)
                    html:cell($config, ., ("tei-cell"), ., ())
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
                        html:cit($config, ., ("tei-cit"), ., ())
                    else
                        $config?apply($config, ./node())
                case element(closer) return
                    epub:block($config, ., ("tei-closer"), .)
                case element(code) return
                    html:inline($config, ., ("tei-code"), .)
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
                case element(dateline) return
                    epub:block($config, ., ("tei-dateline"), .)
                case element(del) return
                    html:inline($config, ., ("tei-del"), .)
                case element(desc) return
                    html:inline($config, ., ("tei-desc"), .)
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
                    html:inline($config, ., ("tei-docAuthor"), .)
                case element(docDate) return
                    html:inline($config, ., ("tei-docDate"), .)
                case element(docEdition) return
                    html:inline($config, ., ("tei-docEdition"), .)
                case element(docImprint) return
                    html:inline($config, ., ("tei-docImprint"), .)
                case element(docTitle) return
                    epub:block($config, ., css:get-rendition(., ("tei-docTitle")), .)
                case element(editor) return
                    if (ancestor::teiHeader) then
                        html:omit($config, ., ("tei-editor1"), .)
                    else
                        html:inline($config, ., ("tei-editor2"), .)
                case element(email) return
                    html:inline($config, ., ("tei-email"), .)
                case element(epigraph) return
                    epub:block($config, ., ("tei-epigraph"), .)
                case element(ex) return
                    html:inline($config, ., ("tei-ex"), .)
                case element(expan) return
                    html:inline($config, ., ("tei-expan"), .)
                case element(figDesc) return
                    html:inline($config, ., ("tei-figDesc"), .)
                case element(figure) return
                    if (head or @rendition='simple:display') then
                        epub:block($config, ., ("tei-figure1"), .)
                    else
                        (: Changed to not show a blue border around the figure :)
                        html:inline($config, ., ("tei-figure2"), .)
                case element(floatingText) return
                    epub:block($config, ., ("tei-floatingText"), .)
                case element(foreign) return
                    html:inline($config, ., ("tei-foreign"), .)
                case element(formula) return
                    if (@rendition='simple:display') then
                        epub:block($config, ., ("tei-formula1"), .)
                    else
                        html:inline($config, ., ("tei-formula2"), .)
                case element(front) return
                    epub:block($config, ., ("tei-front"), .)
                case element(fw) return
                    if (ancestor::p or ancestor::ab) then
                        html:inline($config, ., ("tei-fw1"), .)
                    else
                        epub:block($config, ., ("tei-fw2"), .)
                case element(g) return
                    if (not(text())) then
                        html:glyph($config, ., ("tei-g1"), .)
                    else
                        html:inline($config, ., ("tei-g2"), .)
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
                case element(group) return
                    epub:block($config, ., ("tei-group"), .)
                case element(head) return
                    if (parent::div[@type='frame']) then
                        (: No function found for behavior: frametitle :)
                        $config?apply($config, ./node())
                    else
                        html:heading($config, ., ("tei-head2"), ., ())
                case element(hi) return
                    (: No function found for behavior: alert :)
                    $config?apply($config, ./node())
                case element(imprimatur) return
                    epub:block($config, ., ("tei-imprimatur"), .)
                case element(item) return
                    html:listItem($config, ., ("tei-item"), .)
                case element(l) return
                    epub:block($config, ., css:get-rendition(., ("tei-l")), .)
                case element(label) return
                    html:inline($config, ., ("tei-label"), .)
                case element(lb) return
                    epub:break($config, ., css:get-rendition(., ("tei-lb")), ., 'line', @n)
                case element(lg) return
                    epub:block($config, ., ("tei-lg"), .)
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
                        epub:block($config, ., ("tei-listBibl2"), .)
                case element(measure) return
                    html:inline($config, ., ("tei-measure"), .)
                case element(milestone) return
                    html:inline($config, ., ("tei-milestone"), .)
                case element(name) return
                    html:inline($config, ., ("tei-name"), .)
                case element(note) return
                    if (@place) then
                        epub:note($config, ., ("tei-note1"), ., @place, @n)
                    else
                        if (parent::div and not(@place)) then
                            epub:block($config, ., ("tei-note2"), .)
                        else
                            if (not(@place)) then
                                html:inline($config, ., ("tei-note3"), .)
                            else
                                $config?apply($config, ./node())
                case element(num) return
                    html:inline($config, ., ("tei-num"), .)
                case element(opener) return
                    epub:block($config, ., ("tei-opener"), .)
                case element(orig) return
                    html:inline($config, ., ("tei-orig"), .)
                case element(p) return
                    html:paragraph($config, ., css:get-rendition(., ("tei-p")), .)
                case element(pb) return
                    epub:break($config, ., css:get-rendition(., ("tei-pb")), ., 'page', (concat(if(@n) then concat(@n,' ') else '',if(@facs) then                   concat('@',@facs) else '')))
                case element(pc) return
                    html:inline($config, ., ("tei-pc"), .)
                case element(postscript) return
                    epub:block($config, ., ("tei-postscript"), .)
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
                        epub:block($config, ., css:get-rendition(., ("tei-q1")), .)
                    else
                        if (ancestor::p or ancestor::cell) then
                            html:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                        else
                            epub:block($config, ., css:get-rendition(., ("tei-q3")), .)
                case element(quote) return
                    if (ancestor::p) then
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        html:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                    else
                        (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                        epub:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                case element(ref) return
                    if (not(@target)) then
                        html:inline($config, ., ("tei-ref1"), .)
                    else
                        if (not(text())) then
                            html:link($config, ., ("tei-ref2"), @target, ())
                        else
                            html:link($config, ., ("tei-ref3"), ., ())
                case element(reg) return
                    html:inline($config, ., ("tei-reg"), .)
                case element(relatedItem) return
                    html:inline($config, ., ("tei-relatedItem"), .)
                case element(rhyme) return
                    html:inline($config, ., ("tei-rhyme"), .)
                case element(role) return
                    epub:block($config, ., ("tei-role"), .)
                case element(roleDesc) return
                    epub:block($config, ., ("tei-roleDesc"), .)
                case element(row) return
                    if (@role='label') then
                        html:row($config, ., ("tei-row1"), .)
                    else
                        (: Insert table row. :)
                        html:row($config, ., ("tei-row2"), .)
                case element(rs) return
                    html:inline($config, ., ("tei-rs"), .)
                case element(s) return
                    html:inline($config, ., ("tei-s"), .)
                case element(salute) return
                    if (parent::closer) then
                        html:inline($config, ., ("tei-salute1"), .)
                    else
                        epub:block($config, ., ("tei-salute2"), .)
                case element(seg) return
                    html:inline($config, ., css:get-rendition(., ("tei-seg")), .)
                case element(sic) return
                    if (parent::choice and count(parent::*/*) gt 1) then
                        html:inline($config, ., ("tei-sic1"), .)
                    else
                        html:inline($config, ., ("tei-sic2"), .)
                case element(signed) return
                    if (parent::closer) then
                        epub:block($config, ., ("tei-signed1"), .)
                    else
                        html:inline($config, ., ("tei-signed2"), .)
                case element(sp) return
                    epub:block($config, ., ("tei-sp"), .)
                case element(speaker) return
                    epub:block($config, ., ("tei-speaker"), .)
                case element(spGrp) return
                    epub:block($config, ., ("tei-spGrp"), .)
                case element(stage) return
                    epub:block($config, ., ("tei-stage"), .)
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
                case element(table) return
                    html:table($config, ., ("tei-table"), .)
                case element(fileDesc) return
                    if ($parameters?header='short') then
                        (
                            epub:block($config, ., ("tei-fileDesc1", "header-short"), titleStmt),
                            epub:block($config, ., ("tei-fileDesc2", "header-short"), editionStmt),
                            epub:block($config, ., ("tei-fileDesc3", "header-short"), publicationStmt)
                        )

                    else
                        html:title($config, ., ("tei-fileDesc4"), titleStmt)
                case element(profileDesc) return
                    html:omit($config, ., ("tei-profileDesc"), .)
                case element(revisionDesc) return
                    html:omit($config, ., ("tei-revisionDesc"), .)
                case element(encodingDesc) return
                    html:omit($config, ., ("tei-encodingDesc"), .)
                case element(teiHeader) return
                    if ($parameters?header='short') then
                        epub:block($config, ., ("tei-teiHeader3"), .)
                    else
                        html:metadata($config, ., ("tei-teiHeader4"), .)
                case element(TEI) return
                    html:document($config, ., ("tei-TEI"), .)
                case element(text) return
                    (: tei_simplePrint.odd sets a font and margin on the text body. We don't want that. :)
                    html:body($config, ., ("tei-text"), .)
                case element(time) return
                    html:inline($config, ., ("tei-time"), .)
                case element(title) return
                    if ($parameters?header='short') then
                        html:heading($config, ., ("tei-title1"), ., 5)
                    else
                        if (parent::titleStmt/parent::fileDesc) then
                            (
                                if (preceding-sibling::title) then
                                    html:text($config, ., ("tei-title2"), ' — ')
                                else
                                    (),
                                html:inline($config, ., ("tei-title3"), .)
                            )

                        else
                            if (not(@level) and parent::bibl) then
                                html:inline($config, ., ("tei-title4"), .)
                            else
                                if (@level='m' or not(@level)) then
                                    (
                                        html:inline($config, ., ("tei-title5"), .),
                                        if (ancestor::biblFull) then
                                            html:text($config, ., ("tei-title6"), ', ')
                                        else
                                            ()
                                    )

                                else
                                    if (@level='s' or @level='j') then
                                        (
                                            html:inline($config, ., ("tei-title7"), .),
                                            if (following-sibling::* and     (  ancestor::biblFull)) then
                                                html:text($config, ., ("tei-title8"), ', ')
                                            else
                                                ()
                                        )

                                    else
                                        if (@level='u' or @level='a') then
                                            (
                                                html:inline($config, ., ("tei-title9"), .),
                                                if (following-sibling::* and     (    ancestor::biblFull)) then
                                                    html:text($config, ., ("tei-title10"), '. ')
                                                else
                                                    ()
                                            )

                                        else
                                            html:inline($config, ., ("tei-title11"), .)
                case element(titlePage) return
                    epub:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                case element(titlePart) return
                    epub:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                case element(trailer) return
                    epub:block($config, ., ("tei-trailer"), .)
                case element(unclear) return
                    html:inline($config, ., ("tei-unclear"), .)
                case element(w) return
                    html:inline($config, ., ("tei-w"), .)
                case element(titleStmt) return
                    if ($parameters?header='short') then
                        (
                            html:link($config, ., ("tei-titleStmt3"), title[1], $parameters?doc),
                            epub:block($config, ., ("tei-titleStmt4"), subsequence(title, 2)),
                            epub:block($config, ., ("tei-titleStmt5"), author)
                        )

                    else
                        epub:block($config, ., ("tei-titleStmt6"), .)
                case element(publicationStmt) return
                    (: More than one model without predicate found for ident publicationStmt. Choosing first one. :)
                    epub:block($config, ., ("tei-publicationStmt1"), availability/licence)
                case element(licence) return
                    if (@target) then
                        html:link($config, ., ("tei-licence1", "licence"), 'Licence', @target)
                    else
                        html:omit($config, ., ("tei-licence2"), .)
                case element(edition) return
                    if (ancestor::teiHeader) then
                        epub:block($config, ., ("tei-edition"), .)
                    else
                        $config?apply($config, ./node())
                case element(exist:match) return
                    html:match($config, ., .)
                case element() return
                    if (namespace-uri(.) = 'http://www.tei-c.org/ns/1.0') then
                        $config?apply($config, ./node())
                    else
                        .
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

