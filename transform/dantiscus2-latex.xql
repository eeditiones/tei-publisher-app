(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/dantiscus2.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/dantiscus2/latex";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace mei='http://www.music-encoding.org/ns/mei';

declare namespace pb='http://teipublisher.com/1.0';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";

(: generated template function for element spec: teiHeader :)
declare %private function model:template-teiHeader($config as map(*), $node as node()*, $params as map(*)) {
    ``[\def\volume{`{string-join($config?apply-children($config, $node, $params?content))}`}]``
};
(: generated template function for element spec: ptr :)
declare %private function model:template-ptr($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-mei url="{$config?apply-children($config, $node, $params?url)}" player="player">
                              <pb-option name="appXPath" on="./rdg[contains(@label, 'original')]" off="">Original Clefs</pb-option>
                              </pb-mei></t>/*
};
(: generated template function for element spec: formula :)
declare %private function model:template-formula2($config as map(*), $node as node()*, $params as map(*)) {
    ``[\begin{equation}`{string-join($config?apply-children($config, $node, $params?content))}`\end{equation}]``
};
(: generated template function for element spec: formula :)
declare %private function model:template-formula3($config as map(*), $node as node()*, $params as map(*)) {
    ``[\begin{math}`{string-join($config?apply-children($config, $node, $params?content))}`\end{math}]``
};
(: generated template function for element spec: bibl :)
declare %private function model:template-bibl($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
};
(: generated template function for element spec: mei:mdiv :)
declare %private function model:template-mei_mdiv($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-mei player="player" data="{$config?apply-children($config, $node, $params?data)}"/></t>/*
};
(: generated template function for element spec: titleStmt :)
declare %private function model:template-titleStmt($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><div><h3>Editors</h3><ul>{$config?apply-children($config, $node, $params?editors)}</ul></div></t>/*
};
(: generated template function for element spec: profileDesc :)
declare %private function model:template-profileDesc($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><div>
  <div><h3>Correspondence</h3>{$config?apply-children($config, $node, $params?correspDesc)}</div>
  <div><h3>Places</h3><ol>{$config?apply-children($config, $node, $params?places)}</ol></div>
  <div><h3>Persons</h3><ol>{$config?apply-children($config, $node, $params?persons)}</ol></div>
</div></t>/*
};
(: generated template function for element spec: app :)
declare %private function model:template-app($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-popover persistent="{$config?apply-children($config, $node, $params?persistent)}">{$config?apply-children($config, $node, $params?content)}<span slot="alternate">{$config?apply-children($config, $node, $params?alternate)}</span></pb-popover></t>/*
};
(: generated template function for element spec: editor :)
declare %private function model:template-editor($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><li>{$config?apply-children($config, $node, $params?content)}</li></t>/*
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
                "output": ["latex"],
                "odd": "/db/apps/tei-publisher/odd/dantiscus2.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    let $config := latex:init($config, $input)
    
    return (
        
        let $output := model:apply($config, $input)
        return
            latex:finish($config, $output)
    )
};

declare function model:apply($config as map(*), $input as node()*) {
        let $parameters := 
        if (exists($config?parameters)) then $config?parameters else map {}
        let $mode := 
        if (exists($config?mode)) then $config?mode else ()
        let $trackIds := 
        $parameters?track-ids
        let $get := 
        model:source($parameters, ?)
    return
    $input !         (
            let $node := 
                .
            return
                            typeswitch(.)
                    case element(licence) return
                        latex:omit($config, ., ("tei-licence2", css:map-rend-to-class(.)), .)
                    case element(listBibl) return
                        if (bibl) then
                            latex:list($config, ., ("tei-listBibl1", css:map-rend-to-class(.)), ., ())
                        else
                            latex:block($config, ., ("tei-listBibl2", css:map-rend-to-class(.)), .)
                    case element(castItem) return
                        (: Insert item, rendered as described in parent list rendition. :)
                        latex:listItem($config, ., ("tei-castItem", css:map-rend-to-class(.)), ., ())
                    case element(item) return
                        latex:listItem($config, ., ("tei-item", css:map-rend-to-class(.)), ., ())
                    case element(teiHeader) return
                        let $params := 
                            map {
                                "content": (fileDesc/titleStmt/title[not(@type)], profileDesc/correspDesc)
                            }

                                                let $content := 
                            model:template-teiHeader($config, ., $params)
                        return
                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-teiHeader1", css:map-rend-to-class(.)), $content)
                    case element(figure) return
                        if (head or @rendition='simple:display') then
                            latex:block($config, ., ("tei-figure1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-figure2", css:map-rend-to-class(.)), .)
                    case element(supplied) return
                        if (parent::choice) then
                            latex:inline($config, ., ("tei-supplied1", css:map-rend-to-class(.)), .)
                        else
                            if (@reason='damage') then
                                latex:inline($config, ., ("tei-supplied2", css:map-rend-to-class(.)), .)
                            else
                                if (@reason='illegible' or not(@reason)) then
                                    latex:inline($config, ., ("tei-supplied3", css:map-rend-to-class(.)), .)
                                else
                                    if (@reason='omitted') then
                                        latex:inline($config, ., ("tei-supplied4", css:map-rend-to-class(.)), .)
                                    else
                                        latex:inline($config, ., ("tei-supplied5", css:map-rend-to-class(.)), .)
                    case element(g) return
                        if (not(text())) then
                            latex:glyph($config, ., ("tei-g1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-g2", css:map-rend-to-class(.)), .)
                    case element(author) return
                        if (ancestor::teiHeader) then
                            latex:block($config, ., ("tei-author1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-author2", css:map-rend-to-class(.)), .)
                    case element(castList) return
                        if (child::*) then
                            latex:list($config, ., css:get-rendition(., ("tei-castList", css:map-rend-to-class(.))), castItem, ())
                        else
                            $config?apply($config, ./node())
                    case element(l) return
                        latex:block($config, ., css:get-rendition(., ("tei-l", css:map-rend-to-class(.))), .)
                    case element(ptr) return
                        if (parent::notatedMusic) then
                            (: Load and display external MEI :)
                            let $params := 
                                map {
                                    "url": @target,
                                    "content": .
                                }

                                                        let $content := 
                                model:template-ptr($config, ., $params)
                            return
                                                        latex:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-ptr", css:map-rend-to-class(.)), $content)
                        else
                            $config?apply($config, ./node())
                    case element(closer) return
                        latex:block($config, ., ("tei-closer", css:map-rend-to-class(.)), .)
                    case element(signed) return
                        if (parent::closer) then
                            latex:block($config, ., ("tei-signed1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-signed2", css:map-rend-to-class(.)), .)
                    case element(p) return
                        if (parent::physDesc) then
                            latex:inline($config, ., ("tei-p1", css:map-rend-to-class(.)), .)
                        else
                            latex:paragraph($config, ., css:get-rendition(., ("tei-p2", css:map-rend-to-class(.))), .)
                    case element(list) return
                        latex:list($config, ., css:get-rendition(., ("tei-list", css:map-rend-to-class(.))), item, ())
                    case element(q) return
                        if (l) then
                            latex:block($config, ., css:get-rendition(., ("tei-q1", css:map-rend-to-class(.))), .)
                        else
                            if (ancestor::p or ancestor::cell) then
                                latex:inline($config, ., css:get-rendition(., ("tei-q2", css:map-rend-to-class(.))), .)
                            else
                                latex:block($config, ., css:get-rendition(., ("tei-q3", css:map-rend-to-class(.))), .)
                    case element(pb) return
                        if (@facs) then
                            (: No function found for behavior: webcomponent :)
                            $config?apply($config, ./node())
                        else
                            latex:omit($config, ., ("tei-pb2", css:map-rend-to-class(.)), .)
                    case element(epigraph) return
                        latex:block($config, ., ("tei-epigraph", css:map-rend-to-class(.)), .)
                    case element(lb) return
                        if ($parameters?mode='norm') then
                            latex:omit($config, ., ("tei-lb1", css:map-rend-to-class(.)), .)
                        else
                            latex:break($config, ., css:get-rendition(., ("tei-lb2", css:map-rend-to-class(.))), ., 'line', @n)
                    case element(docTitle) return
                        latex:block($config, ., css:get-rendition(., ("tei-docTitle", css:map-rend-to-class(.))), .)
                    case element(w) return
                        latex:inline($config, ., ("tei-w", css:map-rend-to-class(.)), .)
                    case element(TEI) return
                        latex:document($config, ., ("tei-TEI", css:map-rend-to-class(.)), .)
                    case element(anchor) return
                        latex:anchor($config, ., ("tei-anchor", css:map-rend-to-class(.)), ., @xml:id)
                    case element(titlePage) return
                        latex:block($config, ., css:get-rendition(., ("tei-titlePage", css:map-rend-to-class(.))), .)
                    case element(stage) return
                        latex:block($config, ., ("tei-stage", css:map-rend-to-class(.)), .)
                    case element(lg) return
                        latex:block($config, ., ("tei-lg", css:map-rend-to-class(.)), .)
                    case element(front) return
                        latex:block($config, ., ("tei-front", css:map-rend-to-class(.)), .)
                    case element(formula) return
                        if (@rendition='simple:display') then
                            latex:block($config, ., ("tei-formula1", css:map-rend-to-class(.)), .)
                        else
                            if (@rend="display") then
                                let $params := 
                                    map {
                                        "content": string()
                                    }

                                                                let $content := 
                                    model:template-formula2($config, ., $params)
                                return
                                                                latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-formula2", css:map-rend-to-class(.)), $content)
                            else
                                if (@rend='display') then
                                    (: No function found for behavior: webcomponent :)
                                    $config?apply($config, ./node())
                                else
                                    (: More than one model without predicate found for ident formula. Choosing first one. :)
                                    let $params := 
                                        map {
                                            "content": string()
                                        }

                                                                        let $content := 
                                        model:template-formula3($config, ., $params)
                                    return
                                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-formula3", css:map-rend-to-class(.)), $content)
                    case element(publicationStmt) return
                        latex:omit($config, ., ("tei-publicationStmt2", css:map-rend-to-class(.)), .)
                    case element(choice) return
                        if (sic and corr) then
                            latex:alternate($config, ., ("tei-choice4", "choice", css:map-rend-to-class(.)), ., corr[1], sic[1])
                        else
                            if ($parameters?mode='norm' and abbr and expan) then
                                latex:alternate($config, ., ("tei-choice5", "choice", css:map-rend-to-class(.)), ., expan[1], abbr[1])
                            else
                                if (abbr and expan) then
                                    latex:alternate($config, ., ("tei-choice6", "choice", css:map-rend-to-class(.)), ., abbr[1], expan[1])
                                else
                                    if (orig and reg) then
                                        latex:alternate($config, ., ("tei-choice7", "choice", css:map-rend-to-class(.)), ., reg[1], orig[1])
                                    else
                                        $config?apply($config, ./node())
                    case element(role) return
                        latex:block($config, ., ("tei-role", css:map-rend-to-class(.)), .)
                    case element(hi) return
                        latex:inline($config, ., css:get-rendition(., ("tei-hi", css:map-rend-to-class(.))), .)
                    case element(note) return
                        if (parent::person or parent::place) then
                            latex:inline($config, ., ("tei-note1", css:map-rend-to-class(.)), .)
                        else
                            if (@place) then
                                latex:note($config, ., ("tei-note2", css:map-rend-to-class(.)), ., @place, @n)
                            else
                                if (parent::div and not(@place)) then
                                    latex:block($config, ., ("tei-note3", css:map-rend-to-class(.)), .)
                                else
                                    if (not(@place)) then
                                        latex:inline($config, ., ("tei-note4", css:map-rend-to-class(.)), .)
                                    else
                                        $config?apply($config, ./node())
                    case element(code) return
                        latex:inline($config, ., ("tei-code", css:map-rend-to-class(.)), .)
                    case element(postscript) return
                        latex:block($config, ., ("tei-postscript", css:map-rend-to-class(.)), .)
                    case element(dateline) return
                        latex:block($config, ., ("tei-dateline", css:map-rend-to-class(.)), .)
                    case element(back) return
                        latex:block($config, ., ("tei-back", css:map-rend-to-class(.)), .)
                    case element(edition) return
                        if (ancestor::teiHeader) then
                            latex:block($config, ., ("tei-edition", css:map-rend-to-class(.)), .)
                        else
                            $config?apply($config, ./node())
                    case element(del) return
                        latex:inline($config, ., ("tei-del", css:map-rend-to-class(.)), .)
                    case element(cell) return
                        (: Insert table cell. :)
                        latex:cell($config, ., ("tei-cell", css:map-rend-to-class(.)), ., ())
                    case element(trailer) return
                        latex:block($config, ., ("tei-trailer", css:map-rend-to-class(.)), .)
                    case element(div) return
                        if (@type='title_page') then
                            latex:block($config, ., ("tei-div1", css:map-rend-to-class(.)), .)
                        else
                            if (parent::body or parent::front or parent::back) then
                                latex:section($config, ., ("tei-div2", css:map-rend-to-class(.)), .)
                            else
                                latex:block($config, ., ("tei-div3", css:map-rend-to-class(.)), .)
                    case element(graphic) return
                        latex:graphic($config, ., ("tei-graphic", css:map-rend-to-class(.)), ., @url, @width, @height, @scale, desc)
                    case element(ref) return
                        if (@ana) then
                            (: Kasia's itinerary references :)
                            latex:inline($config, ., ("tei-ref1", "itinerary", css:map-rend-to-class(.)), .)
                        else
                            if (not(@target)) then
                                latex:inline($config, ., ("tei-ref2", css:map-rend-to-class(.)), .)
                            else
                                if (not(node())) then
                                    latex:link($config, ., ("tei-ref3", css:map-rend-to-class(.)), @target, @target, map {})
                                else
                                    latex:link($config, ., ("tei-ref4", css:map-rend-to-class(.)), ., @target, map {})
                    case element(titlePart) return
                        latex:block($config, ., css:get-rendition(., ("tei-titlePart", css:map-rend-to-class(.))), .)
                    case element(ab) return
                        latex:paragraph($config, ., ("tei-ab", css:map-rend-to-class(.)), .)
                    case element(add) return
                        latex:inline($config, ., ("tei-add", css:map-rend-to-class(.)), .)
                    case element(revisionDesc) return
                        latex:omit($config, ., ("tei-revisionDesc", css:map-rend-to-class(.)), .)
                    case element(head) return
                        if ($parameters?header='short') then
                            latex:inline($config, ., ("tei-head1", css:map-rend-to-class(.)), replace(string-join(.//text()[not(parent::ref)]), '^(.*?)[^\w]*$', '$1'))
                        else
                            if (parent::figure) then
                                latex:block($config, ., ("tei-head2", css:map-rend-to-class(.)), .)
                            else
                                if (parent::table) then
                                    latex:block($config, ., ("tei-head3", css:map-rend-to-class(.)), .)
                                else
                                    if (parent::lg) then
                                        latex:block($config, ., ("tei-head4", css:map-rend-to-class(.)), .)
                                    else
                                        if (parent::list) then
                                            latex:block($config, ., ("tei-head5", css:map-rend-to-class(.)), .)
                                        else
                                            if (parent::div) then
                                                latex:heading($config, ., ("tei-head6", css:map-rend-to-class(.)), ., count(ancestor::div))
                                            else
                                                latex:block($config, ., ("tei-head7", css:map-rend-to-class(.)), .)
                    case element(roleDesc) return
                        latex:block($config, ., ("tei-roleDesc", css:map-rend-to-class(.)), .)
                    case element(opener) return
                        latex:block($config, ., ("tei-opener", css:map-rend-to-class(.)), .)
                    case element(speaker) return
                        latex:block($config, ., ("tei-speaker", css:map-rend-to-class(.)), .)
                    case element(time) return
                        latex:inline($config, ., ("tei-time", css:map-rend-to-class(.)), .)
                    case element(castGroup) return
                        if (child::*) then
                            (: Insert list. :)
                            latex:list($config, ., ("tei-castGroup", css:map-rend-to-class(.)), castItem|castGroup, ())
                        else
                            $config?apply($config, ./node())
                    case element(imprimatur) return
                        latex:block($config, ., ("tei-imprimatur", css:map-rend-to-class(.)), .)
                    case element(bibl) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-bibl($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-bibl1", css:map-rend-to-class(.)), $content)
                        else
                            if (parent::listBibl) then
                                latex:listItem($config, ., ("tei-bibl2", css:map-rend-to-class(.)), ., ())
                            else
                                latex:inline($config, ., ("tei-bibl3", css:map-rend-to-class(.)), .)
                    case element(unclear) return
                        latex:inline($config, ., ("tei-unclear", css:map-rend-to-class(.)), .)
                    case element(salute) return
                        if (parent::closer) then
                            latex:inline($config, ., ("tei-salute1", css:map-rend-to-class(.)), .)
                        else
                            latex:block($config, ., ("tei-salute2", css:map-rend-to-class(.)), .)
                    case element(title) return
                        if ($parameters?header='short') then
                            latex:heading($config, ., ("tei-title1", css:map-rend-to-class(.)), ., 5)
                        else
                            if (parent::titleStmt/parent::fileDesc) then
                                (
                                    if (preceding-sibling::title) then
                                        latex:text($config, ., ("tei-title2", css:map-rend-to-class(.)), ' — ')
                                    else
                                        (),
                                    latex:inline($config, ., ("tei-title3", css:map-rend-to-class(.)), .)
                                )

                            else
                                if (not(@level) and parent::bibl) then
                                    latex:inline($config, ., ("tei-title4", css:map-rend-to-class(.)), .)
                                else
                                    if (@level='m' or not(@level)) then
                                        (
                                            latex:inline($config, ., ("tei-title5", css:map-rend-to-class(.)), .),
                                            if (ancestor::biblFull) then
                                                latex:text($config, ., ("tei-title6", css:map-rend-to-class(.)), ', ')
                                            else
                                                ()
                                        )

                                    else
                                        if (@level='s' or @level='j') then
                                            (
                                                latex:inline($config, ., ("tei-title7", css:map-rend-to-class(.)), .),
                                                if (following-sibling::* and     (  ancestor::biblFull)) then
                                                    latex:text($config, ., ("tei-title8", css:map-rend-to-class(.)), ', ')
                                                else
                                                    ()
                                            )

                                        else
                                            if (@level='u' or @level='a') then
                                                (
                                                    latex:inline($config, ., ("tei-title9", css:map-rend-to-class(.)), .),
                                                    if (following-sibling::* and     (    ancestor::biblFull)) then
                                                        latex:text($config, ., ("tei-title10", css:map-rend-to-class(.)), '. ')
                                                    else
                                                        ()
                                                )

                                            else
                                                latex:inline($config, ., ("tei-title11", css:map-rend-to-class(.)), .)
                    case element(date) return
                        latex:inline($config, ., ("tei-date2", css:map-rend-to-class(.)), .)
                    case element(argument) return
                        latex:block($config, ., ("tei-argument", css:map-rend-to-class(.)), .)
                    case element(corr) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            (: simple inline, if in parent choice. :)
                            latex:inline($config, ., ("tei-corr1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-corr2", css:map-rend-to-class(.)), .)
                    case element(foreign) return
                        latex:inline($config, ., ("tei-foreign", css:map-rend-to-class(.)), .)
                    case element(mei:mdiv) return
                        (: Single MEI mdiv needs to be wrapped to create complete MEI document :)
                        let $params := 
                            map {
                                "data": let $title := root($parameters?root)//titleStmt/title let $data :=   <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.0">     <meiHead>         <fileDesc>             <titleStmt>                 <title></title>             </titleStmt>             <pubStmt></pubStmt>         </fileDesc>     </meiHead>     <music>         <body>{.}</body>     </music>   </mei> return   serialize($data),
                                "content": .
                            }

                                                let $content := 
                            model:template-mei_mdiv($config, ., $params)
                        return
                                                latex:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-mei_mdiv", css:map-rend-to-class(.)), $content)
                    case element(cit) return
                        if (child::quote and child::bibl) then
                            (: Insert citation :)
                            latex:cit($config, ., ("tei-cit", css:map-rend-to-class(.)), ., ())
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
                                                        latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-titleStmt1", "editors", css:map-rend-to-class(.)), $content)
                        else
                            (: No function found for behavior: meta :)
                            $config?apply($config, ./node())
                    case element(fileDesc) return
                        if ($parameters?mode='commentary') then
                            latex:block($config, ., ("tei-fileDesc1", css:map-rend-to-class(.)), .)
                        else
                            if ($parameters?header='short') then
                                (
                                    latex:block($config, ., ("tei-fileDesc2", "header-short", css:map-rend-to-class(.)), titleStmt),
                                    latex:block($config, ., ("tei-fileDesc3", "header-short", css:map-rend-to-class(.)), editionStmt),
                                    latex:block($config, ., ("tei-fileDesc4", "header-short", css:map-rend-to-class(.)), publicationStmt),
                                    (: Output abstract containing demo description :)
                                    latex:block($config, ., ("tei-fileDesc5", "sample-description", css:map-rend-to-class(.)), ../profileDesc/abstract)
                                )

                            else
                                latex:title($config, ., ("tei-fileDesc6", css:map-rend-to-class(.)), titleStmt)
                    case element(sic) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            latex:inline($config, ., ("tei-sic1", css:map-rend-to-class(.)), .)
                        else
                            latex:inline($config, ., ("tei-sic2", css:map-rend-to-class(.)), .)
                    case element(spGrp) return
                        latex:block($config, ., ("tei-spGrp", css:map-rend-to-class(.)), .)
                    case element(body) return
                        (
                            latex:index($config, ., ("tei-body1", css:map-rend-to-class(.)), ., 'toc'),
                            latex:block($config, ., ("tei-body2", css:map-rend-to-class(.)), .)
                        )

                    case element(fw) return
                        if (ancestor::p or ancestor::ab) then
                            latex:inline($config, ., ("tei-fw1", css:map-rend-to-class(.)), .)
                        else
                            latex:block($config, ., ("tei-fw2", css:map-rend-to-class(.)), .)
                    case element(encodingDesc) return
                        latex:omit($config, ., ("tei-encodingDesc", css:map-rend-to-class(.)), .)
                    case element(quote) return
                        if (ancestor::p) then
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            latex:inline($config, ., css:get-rendition(., ("tei-quote1", css:map-rend-to-class(.))), .)
                        else
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            latex:block($config, ., css:get-rendition(., ("tei-quote2", css:map-rend-to-class(.))), .)
                    case element(gap) return
                        if (desc) then
                            latex:inline($config, ., ("tei-gap1", css:map-rend-to-class(.)), .)
                        else
                            if (@extent) then
                                latex:inline($config, ., ("tei-gap2", css:map-rend-to-class(.)), @extent)
                            else
                                latex:inline($config, ., ("tei-gap3", css:map-rend-to-class(.)), .)
                    case element(seg) return
                        latex:inline($config, ., css:get-rendition(., ("tei-seg2", css:map-rend-to-class(.))), .)
                    case element(notatedMusic) return
                        latex:figure($config, ., ("tei-notatedMusic", css:map-rend-to-class(.)), (ptr, mei:mdiv), label)
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
                                                        latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-profileDesc1", css:map-rend-to-class(.)), $content)
                        else
                            latex:omit($config, ., ("tei-profileDesc2", css:map-rend-to-class(.)), .)
                    case element(row) return
                        if (@role='label') then
                            latex:row($config, ., ("tei-row1", css:map-rend-to-class(.)), .)
                        else
                            (: Insert table row. :)
                            latex:row($config, ., ("tei-row2", css:map-rend-to-class(.)), .)
                    case element(text) return
                        latex:body($config, ., ("tei-text", css:map-rend-to-class(.)), .)
                    case element(floatingText) return
                        latex:block($config, ., ("tei-floatingText", css:map-rend-to-class(.)), .)
                    case element(sp) return
                        latex:block($config, ., ("tei-sp", css:map-rend-to-class(.)), .)
                    case element(byline) return
                        latex:block($config, ., ("tei-byline", css:map-rend-to-class(.)), .)
                    case element(table) return
                        latex:table($config, ., ("tei-table", css:map-rend-to-class(.)), ., map {})
                    case element(group) return
                        latex:block($config, ., ("tei-group", css:map-rend-to-class(.)), .)
                    case element(cb) return
                        latex:break($config, ., ("tei-cb", css:map-rend-to-class(.)), ., 'column', @n)
                    case element(name) return
                        latex:alternate($config, ., ("tei-name", css:map-rend-to-class(.)), ., ., id(substring-after(@ref, '#'), root($parameters?root))/node())
                    case element(persName) return
                        latex:inline($config, ., ("tei-persName", css:map-rend-to-class(.)), .)
                    case element(rs) return
                        latex:alternate($config, ., ("tei-rs", css:map-rend-to-class(.)), ., ., id(substring-after(@ref, '#'), root($parameters?root))/node())
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
                                                latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-app", css:map-rend-to-class(.)), $content)
                    case element(editor) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-editor($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-editor1", css:map-rend-to-class(.)), $content)
                        else
                            if (preceding-sibling::editor) then
                                (
                                    latex:inline($config, ., ("tei-editor2", css:map-rend-to-class(.)), ', '),
                                    latex:inline($config, ., ("tei-editor3", css:map-rend-to-class(.)), .)
                                )

                            else
                                latex:inline($config, ., ("tei-editor4", css:map-rend-to-class(.)), .)
                    case element(sourceDesc) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-sourceDesc($config, ., $params)
                        return
                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-sourceDesc", css:map-rend-to-class(.)), $content)
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
                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-msDesc", css:map-rend-to-class(.)), $content)
                    case element(person) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-person($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-person1", "person-entry", css:map-rend-to-class(.)), $content)
                        else
                            latex:inline($config, ., ("tei-person2", css:map-rend-to-class(.)), .)
                    case element(place) return
                        if ($parameters?mode='commentary') then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-place($config, ., $params)
                            return
                                                        latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-place1", css:map-rend-to-class(.)), $content)
                        else
                            latex:inline($config, ., ("tei-place2", css:map-rend-to-class(.)), .)
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
                    latex:escapeChars(.)
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

declare function model:process-annotation($html, $context as node()) {
        
    let $classRegex := analyze-string($html/@class, '\s?annotation-([^\s]+)\s?')
    return
        if ($classRegex//fn:match) then (
            if ($html/@data-type) then
                ()
            else
                attribute data-type { ($classRegex//fn:group)[1]/string() },
            if ($html/@data-annotation) then
                ()
            else
                attribute data-annotation {
                    map:merge($context/@* ! map:entry(node-name(.), ./string()))
                    => serialize(map { "method": "json" })
                }
        ) else
            ()
                    
};

declare function model:map($html, $context as node(), $trackIds as item()?) {
        
    if ($trackIds) then
        for $node in $html
        return
            typeswitch ($node)
                case document-node() | comment() | processing-instruction() return 
                    $node
                case element() return
                    if ($node/@class = ("footnote")) then
                        if (local-name($node) = 'pb-popover') then
                            ()
                        else
                            element { node-name($node) }{
                                $node/@*,
                                $node/*[@class="fn-number"],
                                model:map($node/*[@class="fn-content"], $context, $trackIds)
                            }
                    else
                        element { node-name($node) }{
                            attribute data-tei { util:node-id($context) },
                            $node/@*,
                            model:process-annotation($node, $context),
                            $node/node()
                        }
                default return
                    <pb-anchor data-tei="{ util:node-id($context) }">{$node}</pb-anchor>
    else
        $html
                    
};

