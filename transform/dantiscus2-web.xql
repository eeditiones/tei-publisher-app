(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/dantiscus2.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/dantiscus2/web";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace xi='http://www.w3.org/2001/XInclude';

declare namespace pb='http://teipublisher.com/1.0';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

(: generated template function for element spec: profileDesc :)
declare %private function model:template-profileDesc($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><div>
  <div><h3>Correspondence</h3>{$config?apply-children($config, $node, $params?correspDesc)}</div>
  <div><h3>Places</h3><ol>{$config?apply-children($config, $node, $params?places)}</ol></div>
  <div><h3>Persons</h3><ol>{$config?apply-children($config, $node, $params?persons)}</ol></div>
</div></t>/*
};
(: generated template function for element spec: editor :)
declare %private function model:template-editor($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
};
(: generated template function for element spec: bibl :)
declare %private function model:template-bibl($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
};
(: generated template function for element spec: titleStmt :)
declare %private function model:template-titleStmt($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><div><h3>Editors</h3><ul>{$config?apply-children($config, $node, $params?editors)}</ul></div></t>/*
};
(: generated template function for element spec: app :)
declare %private function model:template-app($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-popover persistent="{$config?apply-children($config, $node, $params?persistent)}">{$config?apply-children($config, $node, $params?content)}<span slot="alternate">{$config?apply-children($config, $node, $params?alternate)}</span></pb-popover></t>/*
};
(: generated template function for element spec: sourceDesc :)
declare %private function model:template-sourceDesc($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><div><h3>Sources</h3><ol>{$config?apply-children($config, $node, $params?content)}</ol></div></t>/*
};
(: generated template function for element spec: msDesc :)
declare %private function model:template-msDesc($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>
  <b>{$config?apply-children($config, $node, $params?repository)}</b> 
  {$config?apply-children($config, $node, $params?msid)} ({$config?apply-children($config, $node, $params?desc)})
</li></t>/*
};
(: generated template function for element spec: person :)
declare %private function model:template-person($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
};
(: generated template function for element spec: place :)
declare %private function model:template-place($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["web"],
                "odd": "/db/apps/tei-publisher/odd/dantiscus2.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    
    return (
        html:prepare($config, $input),
    
        let $output := model:apply($config, $input)
        return
            html:finish($config, $output)
    )
};

declare function model:apply($config as map(*), $input as node()*) {
        let $parameters := 
        if (exists($config?parameters)) then $config?parameters else map {}
        let $get := 
        model:source($parameters, ?)
    return
    $input !         (
            let $node := 
                .
            return
                            typeswitch(.)
                    case element(castItem) return
                        (: Insert item, rendered as described in parent list rendition. :)
                        html:listItem($config, ., ("tei-castItem"), ., ())
                    case element(item) return
                        html:listItem($config, ., ("tei-item"), ., ())
                    case element(figure) return
                        if (head or @rendition='simple:display') then
                            html:block($config, ., ("tei-figure1"), .)
                        else
                            html:inline($config, ., ("tei-figure2"), .)
                    case element(teiHeader) return
                        if ($parameters?header='short') then
                            html:block($config, ., ("tei-teiHeader3"), .)
                        else
                            if ($parameters?mode='commentary') then
                                html:inline($config, ., ("tei-teiHeader4"), .)
                            else
                                if ($parameters?mode='title') then
                                    html:inline($config, ., ("tei-teiHeader5"), (fileDesc/titleStmt/title))
                                else
                                    html:metadata($config, ., ("tei-teiHeader6"), .)
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
                    case element(milestone) return
                        html:inline($config, ., ("tei-milestone"), .)
                    case element(ptr) return
                        if (parent::notatedMusic) then
                            html:webcomponent($config, ., ("tei-ptr"), ., 'pb-mei', map {"url": @target})
                        else
                            $config?apply($config, ./node())
                    case element(label) return
                        html:inline($config, ., ("tei-label"), .)
                    case element(signed) return
                        if (parent::closer) then
                            html:block($config, ., ("tei-signed1"), .)
                        else
                            html:inline($config, ., ("tei-signed2"), .)
                    case element(pb) return
                        if (@facs) then
                            html:webcomponent($config, ., ("tei-pb1", "facs"), @n, 'pb-facs-link', map {"facs": replace(@facs, '^img:(.*)$', '$1')})
                        else
                            html:omit($config, ., ("tei-pb2"), .)
                    case element(pc) return
                        html:inline($config, ., ("tei-pc"), .)
                    case element(anchor) return
                        html:anchor($config, ., ("tei-anchor"), ., @xml:id)
                    case element(TEI) return
                        html:document($config, ., ("tei-TEI"), .)
                    case element(formula) return
                        if (@rendition='simple:display') then
                            html:block($config, ., ("tei-formula1"), .)
                        else
                            if (@rend='display') then
                                html:webcomponent($config, ., ("tei-formula2"), ., 'pb-formula', map {"display": true()})
                            else
                                html:webcomponent($config, ., ("tei-formula3"), ., 'pb-formula', map {})
                    case element(choice) return
                        if (sic and corr) then
                            html:alternate($config, ., ("tei-choice4", "choice"), ., corr[1], sic[1], map {})
                        else
                            if ($parameters?mode='norm' and abbr and expan) then
                                html:alternate($config, ., ("tei-choice5", "choice"), ., expan[1], abbr[1], map {})
                            else
                                if (abbr and expan) then
                                    html:alternate($config, ., ("tei-choice6", "choice"), ., abbr[1], expan[1], map {})
                                else
                                    if (orig and reg) then
                                        html:alternate($config, ., ("tei-choice7", "choice"), ., reg[1], orig[1], map {})
                                    else
                                        $config?apply($config, ./node())
                    case element(hi) return
                        if (@rendition) then
                            html:inline($config, ., css:get-rendition(., ("tei-hi1")), .)
                        else
                            if (not(@rendition)) then
                                html:inline($config, ., ("tei-hi2"), .)
                            else
                                $config?apply($config, ./node())
                    case element(code) return
                        html:inline($config, ., ("tei-code"), .)
                    case element(note) return
                        if (parent::person or parent::place) then
                            html:inline($config, ., ("tei-note1"), .)
                        else
                            if (@place) then
                                html:note($config, ., ("tei-note2"), ., @place, @n)
                            else
                                if (parent::div and not(@place)) then
                                    html:block($config, ., ("tei-note3"), .)
                                else
                                    if (not(@place)) then
                                        html:inline($config, ., ("tei-note4"), .)
                                    else
                                        $config?apply($config, ./node())
                    case element(dateline) return
                        html:block($config, ., ("tei-dateline"), .)
                    case element(back) return
                        html:block($config, ., ("tei-back"), .)
                    case element(del) return
                        html:inline($config, ., ("tei-del"), .)
                    case element(trailer) return
                        html:block($config, ., ("tei-trailer"), .)
                    case element(titlePart) return
                        html:block($config, ., css:get-rendition(., ("tei-titlePart")), .)
                    case element(ab) return
                        html:paragraph($config, ., ("tei-ab"), .)
                    case element(revisionDesc) return
                        html:omit($config, ., ("tei-revisionDesc"), .)
                    case element(am) return
                        html:inline($config, ., ("tei-am"), .)
                    case element(subst) return
                        html:inline($config, ., ("tei-subst"), .)
                    case element(roleDesc) return
                        html:block($config, ., ("tei-roleDesc"), .)
                    case element(orig) return
                        html:inline($config, ., ("tei-orig"), .)
                    case element(opener) return
                        html:block($config, ., ("tei-opener"), .)
                    case element(speaker) return
                        html:block($config, ., ("tei-speaker"), .)
                    case element(imprimatur) return
                        html:block($config, ., ("tei-imprimatur"), .)
                    case element(publisher) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            html:omit($config, ., ("tei-publisher"), .)
                        else
                            $config?apply($config, ./node())
                    case element(figDesc) return
                        html:inline($config, ., ("tei-figDesc"), .)
                    case element(rs) return
                        html:alternate($config, ., ("tei-rs"), ., ., id(substring-after(@ref, '#'), root($parameters?root))/node(), map {})
                    case element(foreign) return
                        html:inline($config, ., ("tei-foreign"), .)
                    case element(fileDesc) return
                        if ($parameters?mode='commentary') then
                            html:block($config, ., ("tei-fileDesc1"), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    html:block($config, ., ("tei-fileDesc2", "header-short"), titleStmt),
                                    html:block($config, ., ("tei-fileDesc3", "header-short"), editionStmt),
                                    html:block($config, ., ("tei-fileDesc4", "header-short"), publicationStmt)
                                )

                            else
                                html:title($config, ., ("tei-fileDesc5"), titleStmt)
                    case element(notatedMusic) return
                        html:figure($config, ., ("tei-notatedMusic"), ptr, label)
                    case element(seg) return
                        html:webcomponent($config, ., ("tei-seg1"), ., 'pb-highlight', map {"key": replace(@xml:id, '^s\.(.*)$', 't.$1'), "highlight-self": 'highlight-self'})
                    case element(profileDesc) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "correspDesc": correspDesc,
                                    "places": settingDesc/listPlace/place,
                                    "persons": particDesc/listPerson/person,
                                    "content": .
                                }

                                                        let $content := 
                                model:template-profileDesc($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-profileDesc1"), $content)
                        else
                            html:omit($config, ., ("tei-profileDesc2"), .)
                    case element(email) return
                        html:inline($config, ., ("tei-email"), .)
                    case element(text) return
                        html:body($config, ., ("tei-text"), .)
                    case element(floatingText) return
                        html:block($config, ., ("tei-floatingText"), .)
                    case element(sp) return
                        html:block($config, ., ("tei-sp"), .)
                    case element(abbr) return
                        html:inline($config, ., ("tei-abbr"), .)
                    case element(table) return
                        html:table($config, ., ("tei-table"), .)
                    case element(cb) return
                        html:break($config, ., ("tei-cb"), ., 'column', @n)
                    case element(group) return
                        html:block($config, ., ("tei-group"), .)
                    case element(licence) return
                        if (@target) then
                            html:link($config, ., ("tei-licence1", "licence"), 'Licence', @target, (), map {})
                        else
                            html:omit($config, ., ("tei-licence2"), .)
                    case element(editor) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-editor($config, ., $params)
                            return
                                                        html:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-editor1"), $content)
                        else
                            if (preceding-sibling::editor) then
                                (
                                    html:inline($config, ., ("tei-editor2"), ', '),
                                    html:inline($config, ., ("tei-editor3"), .)
                                )

                            else
                                html:inline($config, ., ("tei-editor4"), .)
                    case element(c) return
                        html:inline($config, ., ("tei-c"), .)
                    case element(listBibl) return
                        if (bibl) then
                            html:list($config, ., ("tei-listBibl1"), bibl, ())
                        else
                            html:block($config, ., ("tei-listBibl2"), .)
                    case element(address) return
                        html:block($config, ., ("tei-address"), .)
                    case element(g) return
                        if (not(text())) then
                            html:glyph($config, ., ("tei-g1"), .)
                        else
                            html:inline($config, ., ("tei-g2"), .)
                    case element(author) return
                        if (ancestor::teiHeader) then
                            html:block($config, ., ("tei-author1"), .)
                        else
                            html:inline($config, ., ("tei-author2"), .)
                    case element(castList) return
                        if (child::*) then
                            html:list($config, ., css:get-rendition(., ("tei-castList")), castItem, ())
                        else
                            $config?apply($config, ./node())
                    case element(l) return
                        html:block($config, ., css:get-rendition(., ("tei-l")), .)
                    case element(closer) return
                        html:block($config, ., ("tei-closer"), .)
                    case element(rhyme) return
                        html:inline($config, ., ("tei-rhyme"), .)
                    case element(list) return
                        if (@rendition) then
                            html:list($config, ., css:get-rendition(., ("tei-list1")), item, ())
                        else
                            if (not(@rendition)) then
                                html:list($config, ., ("tei-list2"), item, ())
                            else
                                $config?apply($config, ./node())
                    case element(p) return
                        if (parent::physDesc) then
                            html:inline($config, ., ("tei-p1"), .)
                        else
                            html:paragraph($config, ., css:get-rendition(., ("tei-p2")), .)
                    case element(measure) return
                        html:inline($config, ., ("tei-measure"), .)
                    case element(q) return
                        if (l) then
                            html:block($config, ., css:get-rendition(., ("tei-q1")), .)
                        else
                            if (ancestor::p or ancestor::cell) then
                                html:inline($config, ., css:get-rendition(., ("tei-q2")), .)
                            else
                                html:block($config, ., css:get-rendition(., ("tei-q3")), .)
                    case element(actor) return
                        html:inline($config, ., ("tei-actor"), .)
                    case element(epigraph) return
                        html:block($config, ., ("tei-epigraph"), .)
                    case element(s) return
                        html:inline($config, ., ("tei-s"), .)
                    case element(docTitle) return
                        html:block($config, ., css:get-rendition(., ("tei-docTitle")), .)
                    case element(lb) return
                        if ($parameters?mode='norm') then
                            html:omit($config, ., ("tei-lb1"), .)
                        else
                            html:break($config, ., css:get-rendition(., ("tei-lb2")), ., 'line', @n)
                    case element(w) return
                        html:inline($config, ., ("tei-w"), .)
                    case element(stage) return
                        html:block($config, ., ("tei-stage"), .)
                    case element(titlePage) return
                        html:block($config, ., css:get-rendition(., ("tei-titlePage")), .)
                    case element(name) return
                        html:alternate($config, ., ("tei-name"), ., ., id(substring-after(@ref, '#'), root($parameters?root))/node(), map {})
                    case element(front) return
                        html:block($config, ., ("tei-front"), .)
                    case element(lg) return
                        html:block($config, ., ("tei-lg"), .)
                    case element(publicationStmt) return
                        html:block($config, ., ("tei-publicationStmt1"), availability/licence)
                    case element(biblScope) return
                        html:inline($config, ., ("tei-biblScope"), .)
                    case element(desc) return
                        html:inline($config, ., ("tei-desc"), .)
                    case element(role) return
                        html:block($config, ., ("tei-role"), .)
                    case element(docEdition) return
                        html:inline($config, ., ("tei-docEdition"), .)
                    case element(num) return
                        html:inline($config, ., ("tei-num"), .)
                    case element(docImprint) return
                        html:inline($config, ., ("tei-docImprint"), .)
                    case element(postscript) return
                        html:block($config, ., ("tei-postscript"), .)
                    case element(edition) return
                        if (ancestor::teiHeader) then
                            html:block($config, ., ("tei-edition"), .)
                        else
                            $config?apply($config, ./node())
                    case element(cell) return
                        (: Insert table cell. :)
                        html:cell($config, ., ("tei-cell"), ., ())
                    case element(relatedItem) return
                        html:inline($config, ., ("tei-relatedItem"), .)
                    case element(div) return
                        if (@type='title_page') then
                            html:block($config, ., ("tei-div1"), .)
                        else
                            if (parent::body or parent::front or parent::back) then
                                html:section($config, ., ("tei-div2"), .)
                            else
                                html:block($config, ., ("tei-div3"), .)
                    case element(graphic) return
                        html:graphic($config, ., ("tei-graphic"), ., @url, @width, @height, @scale, desc)
                    case element(reg) return
                        html:inline($config, ., ("tei-reg"), .)
                    case element(ref) return
                        if (@ana) then
                            (: Kasia's itinerary references :)
                            html:inline($config, ., ("tei-ref1", "itinerary"), .)
                        else
                            if (not(@target)) then
                                html:inline($config, ., ("tei-ref2"), .)
                            else
                                if (not(node())) then
                                    html:link($config, ., ("tei-ref3"), @target, @target, (), map {})
                                else
                                    html:link($config, ., ("tei-ref4"), ., @target, (), map {})
                    case element(pubPlace) return
                        if (ancestor::teiHeader) then
                            (: Omit if located in teiHeader. :)
                            html:omit($config, ., ("tei-pubPlace"), .)
                        else
                            $config?apply($config, ./node())
                    case element(add) return
                        html:inline($config, ., ("tei-add"), .)
                    case element(docDate) return
                        html:inline($config, ., ("tei-docDate"), .)
                    case element(head) return
                        if ($parameters?header='short') then
                            html:inline($config, ., ("tei-head1"), replace(string-join(.//text()[not(parent::ref)]), '^(.*?)[^\w]*$', '$1'))
                        else
                            if (parent::figure) then
                                html:block($config, ., ("tei-head2"), .)
                            else
                                if (parent::table) then
                                    html:block($config, ., ("tei-head3"), .)
                                else
                                    if (parent::lg) then
                                        html:block($config, ., ("tei-head4"), .)
                                    else
                                        if (parent::list) then
                                            html:block($config, ., ("tei-head5"), .)
                                        else
                                            if (parent::div) then
                                                html:heading($config, ., ("tei-head6"), ., count(ancestor::div))
                                            else
                                                html:block($config, ., ("tei-head7"), .)
                    case element(ex) return
                        html:inline($config, ., ("tei-ex"), .)
                    case element(castGroup) return
                        if (child::*) then
                            (: Insert list. :)
                            html:list($config, ., ("tei-castGroup"), castItem|castGroup, ())
                        else
                            $config?apply($config, ./node())
                    case element(time) return
                        html:inline($config, ., ("tei-time"), .)
                    case element(bibl) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-bibl($config, ., $params)
                            return
                                                        html:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-bibl1"), $content)
                        else
                            if (parent::listBibl) then
                                html:listItem($config, ., ("tei-bibl2"), ., ())
                            else
                                html:inline($config, ., ("tei-bibl3"), .)
                    case element(salute) return
                        if (parent::closer) then
                            html:inline($config, ., ("tei-salute1"), .)
                        else
                            html:block($config, ., ("tei-salute2"), .)
                    case element(unclear) return
                        html:inline($config, ., ("tei-unclear"), .)
                    case element(argument) return
                        html:block($config, ., ("tei-argument"), .)
                    case element(date) return
                        if (@when) then
                            html:alternate($config, ., ("tei-date3"), ., ., @when, map {})
                        else
                            if (text()) then
                                html:inline($config, ., ("tei-date4"), .)
                            else
                                $config?apply($config, ./node())
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
                    case element(corr) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            (: simple inline, if in parent choice. :)
                            html:inline($config, ., ("tei-corr1"), .)
                        else
                            html:inline($config, ., ("tei-corr2"), .)
                    case element(cit) return
                        if (child::quote and child::bibl) then
                            (: Insert citation :)
                            html:cit($config, ., ("tei-cit"), ., ())
                        else
                            $config?apply($config, ./node())
                    case element(titleStmt) return
                        if ($parameters?mode='commentary') then
                            (: render editors list :)
                            let $params := 
                                map {
                                    "editors": editor,
                                    "content": .
                                }

                                                        let $content := 
                                model:template-titleStmt($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-titleStmt1", "editors"), $content)
                        else
                            if ($parameters?header='short') then
                                (
                                    html:link($config, ., ("tei-titleStmt4"), title[1], $parameters?doc, (), map {}),
                                    html:block($config, ., ("tei-titleStmt5"), subsequence(title, 2)),
                                    html:block($config, ., ("tei-titleStmt6"), editor),
                                    (: incipit :)
                                    html:block($config, ., ("tei-titleStmt7", "incipit"), root(.)//seg[@type='incipit'])
                                )

                            else
                                html:heading($config, ., ("tei-titleStmt8"), ., 4)
                    case element(sic) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            html:inline($config, ., ("tei-sic1"), .)
                        else
                            html:inline($config, ., ("tei-sic2"), .)
                    case element(expan) return
                        html:inline($config, ., ("tei-expan"), .)
                    case element(body) return
                        (
                            html:index($config, ., ("tei-body1"), 'toc', .),
                            html:block($config, ., ("tei-body2"), .)
                        )

                    case element(spGrp) return
                        html:block($config, ., ("tei-spGrp"), .)
                    case element(fw) return
                        if (ancestor::p or ancestor::ab) then
                            html:inline($config, ., ("tei-fw1"), .)
                        else
                            html:block($config, ., ("tei-fw2"), .)
                    case element(encodingDesc) return
                        html:omit($config, ., ("tei-encodingDesc"), .)
                    case element(addrLine) return
                        html:block($config, ., ("tei-addrLine"), .)
                    case element(gap) return
                        if (desc) then
                            html:inline($config, ., ("tei-gap1"), .)
                        else
                            if (@extent) then
                                html:inline($config, ., ("tei-gap2"), @extent)
                            else
                                html:inline($config, ., ("tei-gap3"), .)
                    case element(quote) return
                        if (ancestor::p) then
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            html:inline($config, ., css:get-rendition(., ("tei-quote1")), .)
                        else
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            html:block($config, ., css:get-rendition(., ("tei-quote2")), .)
                    case element(row) return
                        if (@role='label') then
                            html:row($config, ., ("tei-row1"), .)
                        else
                            (: Insert table row. :)
                            html:row($config, ., ("tei-row2"), .)
                    case element(docAuthor) return
                        html:inline($config, ., ("tei-docAuthor"), .)
                    case element(byline) return
                        html:block($config, ., ("tei-byline"), .)
                    case element(persName) return
                        html:inline($config, ., ("tei-persName"), .)
                    case element(app) return
                        let $params := 
                            map {
                                "content": lem,
                                "alternate": rdg,
                                "persistent": true(),
                                "name": 'pb-popover'
                            }

                                                let $content := 
                            model:template-app($config, ., $params)
                        return
                                                html:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-app"), $content)
                    case element(sourceDesc) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-sourceDesc($config, ., $params)
                        return
                                                html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-sourceDesc"), $content)
                    case element(msDesc) return
                        let $params := 
                            map {
                                "repository": msIdentifier/institution,
                                "msid": msIdentifier/idno,
                                "desc": physDesc/p,
                                "content": .
                            }

                                                let $content := 
                            model:template-msDesc($config, ., $params)
                        return
                                                html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-msDesc"), $content)
                    case element(person) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-person($config, ., $params)
                            return
                                                        html:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-person1", "person-entry"), $content)
                        else
                            html:inline($config, ., ("tei-person2"), .)
                    case element(place) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-place($config, ., $params)
                            return
                                                        html:block(map:merge(($config, map:entry("template", true()))), ., ("tei-place1"), $content)
                        else
                            html:inline($config, ., ("tei-place2"), .)
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
        
    if ($config?template) then
        $content
    else
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

declare function model:source($parameters as map(*), $elem as element()) {
        
    let $id := $elem/@exist:id
    return
        if ($id and $parameters?root) then
            util:node-by-id($parameters?root, $id)
        else
            $elem
};

