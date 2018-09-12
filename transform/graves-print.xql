(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/graves.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/graves/fo";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xi='http://www.w3.org/2001/XInclude';

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
                "odd": "/db/apps/tei-publisher/odd/graves.odd",
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
                    case element(castItem) return
                        (: Insert item, rendered as described in parent list rendition. :)
                        fo:listItem($config, ., ("tei-castItem"), .)
                    case element(item) return
                        fo:listItem($config, ., ("tei-item"), .)
                    case element(figure) return
                        if (head or @rendition='simple:display') then
                            fo:block($config, ., ("tei-figure1"), .)
                        else
                            (: Changed to not show a blue border around the figure :)
                            fo:inline($config, ., ("tei-figure2"), .)
                    case element(teiHeader) return
                        fo:omit($config, ., ("tei-teiHeader2"), .)
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
                    case element(milestone) return
                        fo:inline($config, ., ("tei-milestone"), .)
                    case element(label) return
                        fo:inline($config, ., ("tei-label"), .)
                    case element(signed) return
                        if (parent::closer) then
                            fo:block($config, ., ("tei-signed1"), .)
                        else
                            fo:inline($config, ., ("tei-signed2"), .)
                    case element(pb) return
                        fo:omit($config, ., ("tei-pb"), .)
                    case element(pc) return
                        fo:inline($config, ., ("tei-pc"), .)
                    case element(anchor) return
                        fo:anchor($config, ., ("tei-anchor"), ., @xml:id)
                    case element(TEI) return
                        fo:document($config, ., ("tei-TEI"), .)
                    case element(formula) return
                        if (@rendition='simple:display') then
                            fo:block($config, ., ("tei-formula1"), .)
                        else
                            fo:inline($config, ., ("tei-formula2"), .)
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
                    case element(hi) return
                        if (@rendition) then
                            fo:inline($config, ., css:get-rendition(., ("tei-hi1")), .)
                        else
                            if (not(@rendition)) then
                                fo:inline($config, ., ("tei-hi2"), .)
                            else
                                $config?apply($config, ./node())
                    case element(code) return
                        fo:inline($config, ., ("tei-code"), .)
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
                    case element(dateline) return
                        fo:block($config, ., css:get-rendition(., ("tei-dateline")), .)
                    case element(back) return
                        fo:block($config, ., ("tei-back"), .)
                    case element(del) return
                        fo:inline($config, ., ("tei-del"), .)
                    case element(trailer) return
                        fo:block($config, ., ("tei-trailer"), .)
                    case element(titlePart) return
                        fo:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                    case element(ab) return
                        fo:paragraph($config, ., ("tei-ab"), .)
                    case element(revisionDesc) return
                        fo:omit($config, ., ("tei-revisionDesc"), .)
                    case element(am) return
                        fo:inline($config, ., ("tei-am"), .)
                    case element(subst) return
                        fo:inline($config, ., ("tei-subst"), .)
                    case element(roleDesc) return
                        fo:block($config, ., ("tei-roleDesc"), .)
                    case element(orig) return
                        fo:inline($config, ., ("tei-orig"), .)
                    case element(opener) return
                        fo:block($config, ., ("tei-opener"), .)
                    case element(speaker) return
                        fo:block($config, ., ("tei-speaker"), .)
                    case element(imprimatur) return
                        fo:block($config, ., ("tei-imprimatur"), .)
                    case element(publisher) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            fo:omit($config, ., ("tei-publisher"), .)
                        else
                            $config?apply($config, ./node())
                    case element(figDesc) return
                        fo:inline($config, ., ("tei-figDesc"), .)
                    case element(rs) return
                        fo:inline($config, ., ("tei-rs"), .)
                    case element(foreign) return
                        fo:inline($config, ., ("tei-foreign"), .)
                    case element(fileDesc) return
                        if ($parameters?header='short') then
                            (
                                fo:block($config, ., ("tei-fileDesc1", "header-short"), titleStmt),
                                fo:block($config, ., ("tei-fileDesc2", "header-short"), editionStmt),
                                fo:block($config, ., ("tei-fileDesc3", "header-short"), publicationStmt)
                            )

                        else
                            fo:title($config, ., ("tei-fileDesc4"), titleStmt)
                    case element(seg) return
                        fo:inline($config, ., css:get-rendition(., ("tei-seg")), .)
                    case element(profileDesc) return
                        fo:omit($config, ., ("tei-profileDesc"), .)
                    case element(email) return
                        fo:inline($config, ., ("tei-email"), .)
                    case element(text) return
                        (: tei_simplePrint.odd sets a font and margin on the text body. We don't want that. :)
                        fo:body($config, ., ("tei-text"), .)
                    case element(floatingText) return
                        fo:block($config, ., ("tei-floatingText"), .)
                    case element(sp) return
                        fo:block($config, ., ("tei-sp"), .)
                    case element(abbr) return
                        fo:inline($config, ., ("tei-abbr"), .)
                    case element(table) return
                        fo:table($config, ., ("tei-table"), .)
                    case element(cb) return
                        fo:break($config, ., ("tei-cb"), ., 'column', @n)
                    case element(group) return
                        fo:block($config, ., ("tei-group"), .)
                    case element(licence) return
                        fo:omit($config, ., ("tei-licence2"), .)
                    case element(editor) return
                        if (ancestor::teiHeader) then
                            fo:omit($config, ., ("tei-editor1"), .)
                        else
                            fo:inline($config, ., ("tei-editor2"), .)
                    case element(c) return
                        fo:inline($config, ., ("tei-c"), .)
                    case element(listBibl) return
                        if (bibl) then
                            fo:list($config, ., ("tei-listBibl1"), bibl)
                        else
                            fo:block($config, ., ("tei-listBibl2"), .)
                    case element(address) return
                        fo:block($config, ., ("tei-address"), .)
                    case element(g) return
                        if (not(text())) then
                            fo:glyph($config, ., ("tei-g1"), .)
                        else
                            fo:inline($config, ., ("tei-g2"), .)
                    case element(author) return
                        if (ancestor::teiHeader) then
                            fo:block($config, ., ("tei-author1"), .)
                        else
                            fo:inline($config, ., ("tei-author2"), .)
                    case element(castList) return
                        if (child::*) then
                            fo:list($config, ., css:get-rendition(., ("tei-castList")), castItem)
                        else
                            $config?apply($config, ./node())
                    case element(l) return
                        fo:block($config, ., css:get-rendition(., ("tei-l")), .)
                    case element(closer) return
                        fo:block($config, ., ("tei-closer"), .)
                    case element(rhyme) return
                        fo:inline($config, ., ("tei-rhyme"), .)
                    case element(list) return
                        if (@rendition) then
                            fo:list($config, ., css:get-rendition(., ("tei-list1")), item)
                        else
                            if (not(@rendition)) then
                                fo:list($config, ., ("tei-list2"), item)
                            else
                                $config?apply($config, ./node())
                    case element(p) return
                        fo:paragraph($config, ., css:get-rendition(., ("tei-p")), .)
                    case element(measure) return
                        fo:inline($config, ., ("tei-measure"), .)
                    case element(q) return
                        if (l) then
                            fo:block($config, ., css:get-rendition(., ("tei-q1")), .)
                        else
                            if (ancestor::p or ancestor::cell) then
                                fo:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                            else
                                fo:block($config, ., css:get-rendition(., ("tei-q3")), .)
                    case element(actor) return
                        fo:inline($config, ., ("tei-actor"), .)
                    case element(epigraph) return
                        fo:block($config, ., ("tei-epigraph"), .)
                    case element(s) return
                        fo:inline($config, ., ("tei-s"), .)
                    case element(docTitle) return
                        fo:block($config, ., css:get-rendition(., ("tei-docTitle")), .)
                    case element(lb) return
                        fo:break($config, ., css:get-rendition(., ("tei-lb")), ., 'line', @n)
                    case element(w) return
                        fo:inline($config, ., ("tei-w"), .)
                    case element(stage) return
                        fo:block($config, ., ("tei-stage"), .)
                    case element(titlePage) return
                        fo:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                    case element(name) return
                        if ($parameters?mode='facets' and @type='person') then
                            (: No function found for behavior: webcomponent :)
                            $config?apply($config, ./node())
                        else
                            if ($parameters?mode='facets' and @type='place') then
                                (: No function found for behavior: webcomponent :)
                                $config?apply($config, ./node())
                            else
                                if (@type='place' and id(substring-after(@ref, '#'), root($parameters?root))/location/geo) then
                                    (: No function found for behavior: webcomponent :)
                                    $config?apply($config, ./node())
                                else
                                    if (@type='person' and id(substring-after(@ref, '#'), root($parameters?root))) then
                                        (: No function found for behavior: webcomponent :)
                                        $config?apply($config, ./node())
                                    else
                                        if (@type='place') then
                                            fo:inline($config, ., ("tei-name5"), .)
                                        else
                                            $config?apply($config, ./node())
                    case element(front) return
                        fo:block($config, ., ("tei-front"), .)
                    case element(lg) return
                        fo:block($config, ., ("tei-lg"), .)
                    case element(publicationStmt) return
                        fo:omit($config, ., ("tei-publicationStmt2"), .)
                    case element(biblScope) return
                        fo:inline($config, ., ("tei-biblScope"), .)
                    case element(desc) return
                        fo:inline($config, ., ("tei-desc"), .)
                    case element(role) return
                        fo:block($config, ., ("tei-role"), .)
                    case element(docEdition) return
                        fo:inline($config, ., ("tei-docEdition"), .)
                    case element(num) return
                        fo:inline($config, ., ("tei-num"), .)
                    case element(docImprint) return
                        fo:inline($config, ., ("tei-docImprint"), .)
                    case element(postscript) return
                        (
                            fo:heading($config, ., ("tei-postscript1"), ('Postscript by ', id(substring-after(@resp, '#'), root(.))/persName)),
                            fo:block($config, ., ("tei-postscript2"), .)
                        )

                    case element(edition) return
                        if (ancestor::teiHeader) then
                            fo:block($config, ., ("tei-edition"), .)
                        else
                            $config?apply($config, ./node())
                    case element(cell) return
                        (: Insert table cell. :)
                        fo:cell($config, ., ("tei-cell"), ., ())
                    case element(relatedItem) return
                        fo:inline($config, ., ("tei-relatedItem"), .)
                    case element(div) return
                        if (@type='title_page') then
                            fo:block($config, ., ("tei-div1"), .)
                        else
                            if (parent::body or parent::front or parent::back) then
                                fo:section($config, ., ("tei-div2"), .)
                            else
                                fo:block($config, ., ("tei-div3"), .)
                    case element(graphic) return
                        fo:graphic($config, ., ("tei-graphic"), ., @url, @width, @height, @scale, desc)
                    case element(reg) return
                        fo:inline($config, ., ("tei-reg"), .)
                    case element(ref) return
                        if (not(@target)) then
                            fo:inline($config, ., ("tei-ref1"), .)
                        else
                            if (not(text())) then
                                fo:link($config, ., ("tei-ref2"), @target, ())
                            else
                                fo:link($config, ., ("tei-ref3"), ., ())
                    case element(pubPlace) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            fo:omit($config, ., ("tei-pubPlace"), .)
                        else
                            $config?apply($config, ./node())
                    case element(add) return
                        fo:inline($config, ., ("tei-add"), .)
                    case element(docDate) return
                        fo:inline($config, ., ("tei-docDate"), .)
                    case element(head) return
                        if ($parameters?header='short') then
                            fo:inline($config, ., ("tei-head1"), replace(string-join(.//text()[not(parent::ref)]), '^(.*?)[^\w]*$', '$1'))
                        else
                            if (parent::figure) then
                                fo:block($config, ., ("tei-head2"), .)
                            else
                                if (parent::table) then
                                    fo:block($config, ., ("tei-head3"), .)
                                else
                                    if (parent::lg) then
                                        fo:block($config, ., ("tei-head4"), .)
                                    else
                                        if (parent::list) then
                                            fo:block($config, ., ("tei-head5"), .)
                                        else
                                            if (parent::div) then
                                                fo:heading($config, ., ("tei-head6"), .)
                                            else
                                                fo:block($config, ., ("tei-head7"), .)
                    case element(ex) return
                        fo:inline($config, ., ("tei-ex"), .)
                    case element(castGroup) return
                        if (child::*) then
                            (: Insert list. :)
                            fo:list($config, ., ("tei-castGroup"), castItem|castGroup)
                        else
                            $config?apply($config, ./node())
                    case element(time) return
                        fo:inline($config, ., ("tei-time"), .)
                    case element(bibl) return
                        if (parent::listBibl) then
                            fo:listItem($config, ., ("tei-bibl1"), .)
                        else
                            fo:inline($config, ., ("tei-bibl2"), .)
                    case element(salute) return
                        if (parent::closer) then
                            fo:inline($config, ., ("tei-salute1"), .)
                        else
                            fo:block($config, ., ("tei-salute2"), .)
                    case element(unclear) return
                        fo:inline($config, ., ("tei-unclear"), .)
                    case element(argument) return
                        fo:block($config, ., ("tei-argument"), .)
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
                    case element(corr) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            (: simple inline, if in parent choice. :)
                            fo:inline($config, ., ("tei-corr1"), .)
                        else
                            fo:inline($config, ., ("tei-corr2"), .)
                    case element(cit) return
                        if (child::quote and child::bibl) then
                            (: Insert citation :)
                            fo:cit($config, ., ("tei-cit"), ., ())
                        else
                            $config?apply($config, ./node())
                    case element(titleStmt) return
                        fo:heading($config, ., ("tei-titleStmt2"), .)
                    case element(sic) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            fo:inline($config, ., ("tei-sic1"), .)
                        else
                            fo:inline($config, ., ("tei-sic2"), .)
                    case element(expan) return
                        fo:inline($config, ., ("tei-expan"), .)
                    case element(body) return
                        if ($parameters?mode='facets') then
                            (
                                fo:heading($config, ., ("tei-body1"), 'Places'),
                                fo:block($config, ., ("tei-body2"), for $n in .//name[@type='place'] group by $ref := $n/@ref order by $ref return $n[1]),
                                fo:heading($config, ., ("tei-body3"), 'People'),
                                fo:section($config, ., ("tei-body4"), for $n in .//name[@type='person'] group by $ref := $n/@ref order by $ref return $n[1])
                            )

                        else
                            (
                                fo:index($config, ., ("tei-body5"), ., 'toc'),
                                fo:block($config, ., ("tei-body6"), .)
                            )

                    case element(spGrp) return
                        fo:block($config, ., ("tei-spGrp"), .)
                    case element(fw) return
                        if (ancestor::p or ancestor::ab) then
                            fo:inline($config, ., ("tei-fw1"), .)
                        else
                            fo:block($config, ., ("tei-fw2"), .)
                    case element(encodingDesc) return
                        fo:omit($config, ., ("tei-encodingDesc"), .)
                    case element(addrLine) return
                        fo:block($config, ., ("tei-addrLine"), .)
                    case element(gap) return
                        if (desc) then
                            fo:inline($config, ., ("tei-gap1"), .)
                        else
                            if (@extent) then
                                fo:inline($config, ., ("tei-gap2"), @extent)
                            else
                                fo:inline($config, ., ("tei-gap3"), .)
                    case element(quote) return
                        if (ancestor::p) then
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            fo:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                        else
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            fo:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                    case element(row) return
                        if (@role='label') then
                            fo:row($config, ., ("tei-row1"), .)
                        else
                            (: Insert table row. :)
                            fo:row($config, ., ("tei-row2"), .)
                    case element(docAuthor) return
                        fo:inline($config, ., ("tei-docAuthor"), .)
                    case element(byline) return
                        fo:block($config, ., ("tei-byline"), .)
                    case element(place) return
                        (
                            fo:heading($config, ., ("tei-place1"), string-join(placeName, ', ')),
                            if (location/geo) then
                                fo:block($config, ., ("tei-place2"), location/geo)
                            else
                                (),
                            fo:block($config, ., ("tei-place3"), string-join(location/*[not(self::geo)], ', ')),
                            fo:block($config, ., ("tei-place4"), note/node())
                        )

                    case element(geo) return
                        (
                            fo:inline($config, ., ("tei-geo1"), 'Location: '),
                            (: No function found for behavior: webcomponent :)
                            $config?apply($config, ./node())
                        )

                    case element(person) return
                        (
                            fo:heading($config, ., ("tei-person1"), persName),
                            if (birth or death or occupation) then
                                fo:block($config, ., ("tei-person2"), (occupation, birth, death))
                            else
                                (),
                            if (idno) then
                                fo:block($config, ., ("tei-person3"), idno)
                            else
                                (),
                            fo:block($config, ., ("tei-person4"), note/node())
                        )

                    case element(persName) return
                        if (forename or surname) then
                            fo:inline($config, ., ("tei-persName1"), (forename, ' ', surname[not(@type='married')], if (surname[@type='married']) then (' (', string-join(surname[@type='married'], ', '), ')') else ()))
                        else
                            fo:inline($config, ., ("tei-persName2"), .)
                    case element(birth) return
                        if (following-sibling::death) then
                            fo:inline($config, ., ("tei-birth1"), ('* ', ., '; '))
                        else
                            fo:inline($config, ., ("tei-birth2"), ('* ', .))
                    case element(death) return
                        fo:inline($config, ., ("tei-death"), ('✝', .))
                    case element(occupation) return
                        fo:inline($config, ., ("tei-occupation"), (., ' '))
                    case element(idno) return
                        if (@type='VIAF' and following-sibling::idno) then
                            fo:link($config, ., ("tei-idno1"), 'VIAF', 'https://viaf.org/viaf/' || string() || '/')
                        else
                            if (@type='VIAF') then
                                fo:link($config, ., ("tei-idno2"), 'VIAF', 'https://viaf.org/viaf/' || string() || '/')
                            else
                                if (@type='LC-Name-Authority-File' and following-sibling::idno) then
                                    fo:link($config, ., ("tei-idno3"), 'LoC Authority', 'https://lccn.loc.gov/' || string())
                                else
                                    if (@type='LC-Name-Authority-File') then
                                        fo:link($config, ., ("tei-idno4"), 'LoC Authority', 'https://lccn.loc.gov/' || string())
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

