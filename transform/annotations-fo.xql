(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/annotations.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/annotations/fo";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace mei='http://www.music-encoding.org/ns/mei';

declare namespace pb='http://teipublisher.com/1.0';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace fo="http://www.tei-c.org/tei-simple/xquery/functions/fo";

(: generated template function for element spec: ptr :)
declare %private function model:template-ptr($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-mei url="{$config?apply-children($config, $node, $params?url)}" player="player">
                              <pb-option name="appXPath" on="./rdg[contains(@label, 'original')]" off="">Original Clefs</pb-option>
                              </pb-mei></t>/*
};
(: generated template function for element spec: choice :)
declare %private function model:template-choice($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><span class="annotation annotation-sic" data-type="sic" data-annotation="{{&#34;corr&#34;: &#34;{$config?apply-children($config, $node, $params?corr)}&#34;}}">{$config?apply-children($config, $node, $params?sic)}</span></t>/*
};
(: generated template function for element spec: choice :)
declare %private function model:template-choice2($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><span class="annotation annotation-sic" data-type="abbr" data-annotation="{{&#34;expan&#34;: &#34;{$config?apply-children($config, $node, $params?expan)}&#34;}}">{$config?apply-children($config, $node, $params?abbr)}</span></t>/*
};
(: generated template function for element spec: choice :)
declare %private function model:template-choice3($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><span class="annotation annotation-reg" data-type="reg" data-annotation="{{&#34;reg&#34;: &#34;{$config?apply-children($config, $node, $params?reg)}&#34;}}">{$config?apply-children($config, $node, $params?orig)}</span></t>/*
};
(: generated template function for element spec: mei:mdiv :)
declare %private function model:template-mei_mdiv($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><pb-mei player="player" data="{$config?apply-children($config, $node, $params?data)}"/></t>/*
};
(: generated template function for element spec: app :)
declare %private function model:template-app($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><span class="annotation annotation-app" data-type="app" data-annotation="{{{$config?apply-children($config, $node, $params?rdg)}}}">{$config?apply-children($config, $node, $params?lem)}</span></t>/*
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["fo"],
                "odd": "/db/apps/tei-publisher/odd/annotations.odd",
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
                        fo:omit($config, ., ("tei-licence2", css:map-rend-to-class(.)), .)
                    case element(listBibl) return
                        if (bibl) then
                            fo:list($config, ., ("tei-listBibl1", css:map-rend-to-class(.)), ., ())
                        else
                            fo:block($config, ., ("tei-listBibl2", css:map-rend-to-class(.)), .)
                    case element(castItem) return
                        (: Insert item, rendered as described in parent list rendition. :)
                        fo:listItem($config, ., ("tei-castItem", css:map-rend-to-class(.)), ., ())
                    case element(item) return
                        fo:listItem($config, ., ("tei-item", css:map-rend-to-class(.)), ., ())
                    case element(teiHeader) return
                        fo:omit($config, ., ("tei-teiHeader2", css:map-rend-to-class(.)), .)
                    case element(figure) return
                        if (head or @rendition='simple:display') then
                            fo:block($config, ., ("tei-figure1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-figure2", css:map-rend-to-class(.)), .)
                    case element(supplied) return
                        if (parent::choice) then
                            fo:inline($config, ., ("tei-supplied1", css:map-rend-to-class(.)), .)
                        else
                            if (@reason='damage') then
                                fo:inline($config, ., ("tei-supplied2", css:map-rend-to-class(.)), .)
                            else
                                if (@reason='illegible' or not(@reason)) then
                                    fo:inline($config, ., ("tei-supplied3", css:map-rend-to-class(.)), .)
                                else
                                    if (@reason='omitted') then
                                        fo:inline($config, ., ("tei-supplied4", css:map-rend-to-class(.)), .)
                                    else
                                        fo:inline($config, ., ("tei-supplied5", css:map-rend-to-class(.)), .)
                    case element(g) return
                        if (not(text())) then
                            fo:glyph($config, ., ("tei-g1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-g2", css:map-rend-to-class(.)), .)
                    case element(author) return
                        if (ancestor::teiHeader) then
                            fo:block($config, ., ("tei-author1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-author2", css:map-rend-to-class(.)), .)
                    case element(castList) return
                        if (child::*) then
                            fo:list($config, ., css:get-rendition(., ("tei-castList", css:map-rend-to-class(.))), castItem, ())
                        else
                            $config?apply($config, ./node())
                    case element(l) return
                        fo:block($config, ., css:get-rendition(., ("tei-l", css:map-rend-to-class(.))), .)
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
                                                        fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-ptr", css:map-rend-to-class(.)), $content)
                        else
                            $config?apply($config, ./node())
                    case element(closer) return
                        fo:block($config, ., ("tei-closer", css:map-rend-to-class(.)), .)
                    case element(signed) return
                        if (parent::closer) then
                            fo:block($config, ., ("tei-signed1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-signed2", css:map-rend-to-class(.)), .)
                    case element(p) return
                        fo:paragraph($config, ., css:get-rendition(., ("tei-p2", css:map-rend-to-class(.))), .)
                    case element(list) return
                        fo:list($config, ., css:get-rendition(., ("tei-list", css:map-rend-to-class(.))), item, ())
                    case element(q) return
                        if (l) then
                            fo:block($config, ., css:get-rendition(., ("tei-q1", css:map-rend-to-class(.))), .)
                        else
                            if (ancestor::p or ancestor::cell) then
                                fo:inline($config, ., css:get-rendition(., ("tei-q2", css:map-rend-to-class(.))), .)
                            else
                                fo:block($config, ., css:get-rendition(., ("tei-q3", css:map-rend-to-class(.))), .)
                    case element(pb) return
                        fo:inline($config, ., ("tei-pb", css:map-rend-to-class(.)), .)
                    case element(epigraph) return
                        fo:block($config, ., ("tei-epigraph", css:map-rend-to-class(.)), .)
                    case element(lb) return
                        fo:break($config, ., css:get-rendition(., ("tei-lb", css:map-rend-to-class(.))), ., 'line', @n)
                    case element(docTitle) return
                        fo:block($config, ., css:get-rendition(., ("tei-docTitle", css:map-rend-to-class(.))), .)
                    case element(w) return
                        fo:inline($config, ., ("tei-w", css:map-rend-to-class(.)), .)
                    case element(TEI) return
                        fo:document($config, ., ("tei-TEI", css:map-rend-to-class(.)), .)
                    case element(anchor) return
                        fo:anchor($config, ., ("tei-anchor", css:map-rend-to-class(.)), ., @xml:id)
                    case element(titlePage) return
                        fo:block($config, ., css:get-rendition(., ("tei-titlePage", css:map-rend-to-class(.))), .)
                    case element(stage) return
                        fo:block($config, ., ("tei-stage", css:map-rend-to-class(.)), .)
                    case element(lg) return
                        fo:block($config, ., ("tei-lg", css:map-rend-to-class(.)), .)
                    case element(front) return
                        fo:block($config, ., ("tei-front", css:map-rend-to-class(.)), .)
                    case element(formula) return
                        if (@rendition='simple:display') then
                            fo:block($config, ., ("tei-formula1", css:map-rend-to-class(.)), .)
                        else
                            if (@rend='display') then
                                (: No function found for behavior: webcomponent :)
                                $config?apply($config, ./node())
                            else
                                (: No function found for behavior: webcomponent :)
                                $config?apply($config, ./node())
                    case element(publicationStmt) return
                        fo:omit($config, ., ("tei-publicationStmt2", css:map-rend-to-class(.)), .)
                    case element(choice) return
                        if (sic and corr) then
                            let $params := 
                                map {
                                    "sic": sic[1]/node(),
                                    "corr": corr[1]/node(),
                                    "content": .
                                }

                                                        let $content := 
                                model:template-choice($config, ., $params)
                            return
                                                        fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-choice1", css:map-rend-to-class(.)), $content)
                        else
                            if (abbr and expan) then
                                let $params := 
                                    map {
                                        "expan": expan[1]/node(),
                                        "abbr": abbr[1]/node(),
                                        "content": .
                                    }

                                                                let $content := 
                                    model:template-choice2($config, ., $params)
                                return
                                                                fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-choice2", css:map-rend-to-class(.)), $content)
                            else
                                if (orig and reg) then
                                    let $params := 
                                        map {
                                            "reg": reg[1]/node(),
                                            "orig": orig[1]/node(),
                                            "content": .
                                        }

                                                                        let $content := 
                                        model:template-choice3($config, ., $params)
                                    return
                                                                        fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-choice3", css:map-rend-to-class(.)), $content)
                                else
                                    $config?apply($config, ./node())
                    case element(role) return
                        fo:block($config, ., ("tei-role", css:map-rend-to-class(.)), .)
                    case element(hi) return
                        fo:inline($config, ., css:get-rendition(., ("tei-hi", "annotation", "annotation-hi", css:map-rend-to-class(.))), .)
                    case element(note) return
                        if (@type='annotation') then
                            fo:omit($config, ., ("tei-note1", css:map-rend-to-class(.)), .)
                        else
                            fo:note($config, ., ("tei-note2", css:map-rend-to-class(.)), ., @place, @n)
                    case element(code) return
                        fo:inline($config, ., ("tei-code", css:map-rend-to-class(.)), .)
                    case element(postscript) return
                        fo:block($config, ., ("tei-postscript", css:map-rend-to-class(.)), .)
                    case element(dateline) return
                        fo:block($config, ., ("tei-dateline", css:map-rend-to-class(.)), .)
                    case element(back) return
                        fo:block($config, ., ("tei-back", css:map-rend-to-class(.)), .)
                    case element(edition) return
                        if (ancestor::teiHeader) then
                            fo:block($config, ., ("tei-edition", css:map-rend-to-class(.)), .)
                        else
                            $config?apply($config, ./node())
                    case element(del) return
                        fo:inline($config, ., ("tei-del", css:map-rend-to-class(.)), .)
                    case element(cell) return
                        (: Insert table cell. :)
                        fo:cell($config, ., ("tei-cell", css:map-rend-to-class(.)), ., ())
                    case element(trailer) return
                        fo:block($config, ., ("tei-trailer", css:map-rend-to-class(.)), .)
                    case element(div) return
                        if (@type='title_page') then
                            fo:block($config, ., ("tei-div1", css:map-rend-to-class(.)), .)
                        else
                            if (parent::body or parent::front or parent::back) then
                                fo:section($config, ., ("tei-div2", css:map-rend-to-class(.)), .)
                            else
                                fo:block($config, ., ("tei-div3", css:map-rend-to-class(.)), .)
                    case element(graphic) return
                        fo:graphic($config, ., ("tei-graphic", css:map-rend-to-class(.)), ., @url, @width, @height, @scale, desc)
                    case element(ref) return
                        fo:inline($config, ., ("tei-ref", "annotation", "annotation-ref", css:map-rend-to-class(.)), .)
                    case element(titlePart) return
                        fo:block($config, ., css:get-rendition(., ("tei-titlePart", css:map-rend-to-class(.))), .)
                    case element(ab) return
                        fo:paragraph($config, ., ("tei-ab", css:map-rend-to-class(.)), .)
                    case element(add) return
                        fo:inline($config, ., ("tei-add", css:map-rend-to-class(.)), .)
                    case element(revisionDesc) return
                        fo:omit($config, ., ("tei-revisionDesc", css:map-rend-to-class(.)), .)
                    case element(head) return
                        if ($parameters?header='short') then
                            fo:inline($config, ., ("tei-head1", css:map-rend-to-class(.)), replace(string-join(.//text()[not(parent::ref)]), '^(.*?)[^\w]*$', '$1'))
                        else
                            if (parent::figure) then
                                fo:block($config, ., ("tei-head2", css:map-rend-to-class(.)), .)
                            else
                                if (parent::table) then
                                    fo:block($config, ., ("tei-head3", css:map-rend-to-class(.)), .)
                                else
                                    if (parent::lg) then
                                        fo:block($config, ., ("tei-head4", css:map-rend-to-class(.)), .)
                                    else
                                        if (parent::list) then
                                            fo:block($config, ., ("tei-head5", css:map-rend-to-class(.)), .)
                                        else
                                            if (parent::div) then
                                                fo:heading($config, ., ("tei-head6", css:map-rend-to-class(.)), ., count(ancestor::div))
                                            else
                                                fo:block($config, ., ("tei-head7", css:map-rend-to-class(.)), .)
                    case element(roleDesc) return
                        fo:block($config, ., ("tei-roleDesc", css:map-rend-to-class(.)), .)
                    case element(opener) return
                        fo:block($config, ., ("tei-opener", css:map-rend-to-class(.)), .)
                    case element(speaker) return
                        fo:block($config, ., ("tei-speaker", css:map-rend-to-class(.)), .)
                    case element(time) return
                        fo:inline($config, ., ("tei-time", css:map-rend-to-class(.)), .)
                    case element(castGroup) return
                        if (child::*) then
                            (: Insert list. :)
                            fo:list($config, ., ("tei-castGroup", css:map-rend-to-class(.)), castItem|castGroup, ())
                        else
                            $config?apply($config, ./node())
                    case element(imprimatur) return
                        fo:block($config, ., ("tei-imprimatur", css:map-rend-to-class(.)), .)
                    case element(bibl) return
                        if (parent::listBibl) then
                            fo:listItem($config, ., ("tei-bibl1", css:map-rend-to-class(.)), ., ())
                        else
                            fo:inline($config, ., ("tei-bibl2", css:map-rend-to-class(.)), .)
                    case element(unclear) return
                        fo:inline($config, ., ("tei-unclear", css:map-rend-to-class(.)), .)
                    case element(salute) return
                        if (parent::closer) then
                            fo:inline($config, ., ("tei-salute1", css:map-rend-to-class(.)), .)
                        else
                            fo:block($config, ., ("tei-salute2", css:map-rend-to-class(.)), .)
                    case element(title) return
                        if ($parameters?header='short') then
                            fo:heading($config, ., ("tei-title1", css:map-rend-to-class(.)), ., 5)
                        else
                            if (parent::titleStmt/parent::fileDesc) then
                                (
                                    if (preceding-sibling::title) then
                                        fo:text($config, ., ("tei-title2", css:map-rend-to-class(.)), ' — ')
                                    else
                                        (),
                                    fo:inline($config, ., ("tei-title3", css:map-rend-to-class(.)), .)
                                )

                            else
                                if (not(@level) and parent::bibl) then
                                    fo:inline($config, ., ("tei-title4", css:map-rend-to-class(.)), .)
                                else
                                    if (@level='m' or not(@level)) then
                                        (
                                            fo:inline($config, ., ("tei-title5", css:map-rend-to-class(.)), .),
                                            if (ancestor::biblFull) then
                                                fo:text($config, ., ("tei-title6", css:map-rend-to-class(.)), ', ')
                                            else
                                                ()
                                        )

                                    else
                                        if (@level='s' or @level='j') then
                                            (
                                                fo:inline($config, ., ("tei-title7", css:map-rend-to-class(.)), .),
                                                if (following-sibling::* and     (  ancestor::biblFull)) then
                                                    fo:text($config, ., ("tei-title8", css:map-rend-to-class(.)), ', ')
                                                else
                                                    ()
                                            )

                                        else
                                            if (@level='u' or @level='a') then
                                                (
                                                    fo:inline($config, ., ("tei-title9", css:map-rend-to-class(.)), .),
                                                    if (following-sibling::* and     (    ancestor::biblFull)) then
                                                        fo:text($config, ., ("tei-title10", css:map-rend-to-class(.)), '. ')
                                                    else
                                                        ()
                                                )

                                            else
                                                fo:inline($config, ., ("tei-title11", css:map-rend-to-class(.)), .)
                    case element(date) return
                        fo:inline($config, ., ("tei-date", "annotation", "annotation-date", css:map-rend-to-class(.)), .)
                    case element(argument) return
                        fo:block($config, ., ("tei-argument", css:map-rend-to-class(.)), .)
                    case element(corr) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            (: simple inline, if in parent choice. :)
                            fo:inline($config, ., ("tei-corr1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-corr2", css:map-rend-to-class(.)), .)
                    case element(foreign) return
                        fo:inline($config, ., ("tei-foreign", css:map-rend-to-class(.)), .)
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
                                                fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-mei_mdiv", css:map-rend-to-class(.)), $content)
                    case element(cit) return
                        if (child::quote and child::bibl) then
                            (: Insert citation :)
                            fo:cit($config, ., ("tei-cit", css:map-rend-to-class(.)), ., ())
                        else
                            $config?apply($config, ./node())
                    case element(titleStmt) return
                        fo:heading($config, ., ("tei-titleStmt2", css:map-rend-to-class(.)), ., ())
                    case element(fileDesc) return
                        if ($parameters?header='short') then
                            (
                                fo:block($config, ., ("tei-fileDesc1", "header-short", css:map-rend-to-class(.)), titleStmt),
                                fo:block($config, ., ("tei-fileDesc2", "header-short", css:map-rend-to-class(.)), editionStmt),
                                fo:block($config, ., ("tei-fileDesc3", "header-short", css:map-rend-to-class(.)), publicationStmt),
                                (: Output abstract containing demo description :)
                                fo:block($config, ., ("tei-fileDesc4", "sample-description", css:map-rend-to-class(.)), ../profileDesc/abstract)
                            )

                        else
                            fo:title($config, ., ("tei-fileDesc5", css:map-rend-to-class(.)), titleStmt)
                    case element(sic) return
                        if (parent::choice and count(parent::*/*) gt 1) then
                            fo:inline($config, ., ("tei-sic1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-sic2", css:map-rend-to-class(.)), .)
                    case element(spGrp) return
                        fo:block($config, ., ("tei-spGrp", css:map-rend-to-class(.)), .)
                    case element(body) return
                        (
                            fo:index($config, ., ("tei-body1", css:map-rend-to-class(.)), ., 'toc'),
                            fo:block($config, ., ("tei-body2", css:map-rend-to-class(.)), .)
                        )

                    case element(fw) return
                        if (ancestor::p or ancestor::ab) then
                            fo:inline($config, ., ("tei-fw1", css:map-rend-to-class(.)), .)
                        else
                            fo:block($config, ., ("tei-fw2", css:map-rend-to-class(.)), .)
                    case element(encodingDesc) return
                        fo:omit($config, ., ("tei-encodingDesc", css:map-rend-to-class(.)), .)
                    case element(quote) return
                        if (ancestor::p) then
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            fo:inline($config, ., css:get-rendition(., ("tei-quote1", css:map-rend-to-class(.))), .)
                        else
                            (: If it is inside a paragraph then it is inline, otherwise it is block level :)
                            fo:block($config, ., css:get-rendition(., ("tei-quote2", css:map-rend-to-class(.))), .)
                    case element(gap) return
                        if (desc) then
                            fo:inline($config, ., ("tei-gap1", css:map-rend-to-class(.)), .)
                        else
                            if (@extent) then
                                fo:inline($config, ., ("tei-gap2", css:map-rend-to-class(.)), @extent)
                            else
                                fo:inline($config, ., ("tei-gap3", css:map-rend-to-class(.)), .)
                    case element(seg) return
                        fo:inline($config, ., css:get-rendition(., ("tei-seg", css:map-rend-to-class(.))), .)
                    case element(notatedMusic) return
                        fo:figure($config, ., ("tei-notatedMusic", css:map-rend-to-class(.)), (ptr, mei:mdiv), label)
                    case element(profileDesc) return
                        fo:omit($config, ., ("tei-profileDesc", css:map-rend-to-class(.)), .)
                    case element(row) return
                        if (@role='label') then
                            fo:row($config, ., ("tei-row1", css:map-rend-to-class(.)), .)
                        else
                            (: Insert table row. :)
                            fo:row($config, ., ("tei-row2", css:map-rend-to-class(.)), .)
                    case element(text) return
                        fo:body($config, ., ("tei-text", css:map-rend-to-class(.)), .)
                    case element(floatingText) return
                        fo:block($config, ., ("tei-floatingText", css:map-rend-to-class(.)), .)
                    case element(sp) return
                        fo:block($config, ., ("tei-sp", css:map-rend-to-class(.)), .)
                    case element(byline) return
                        fo:block($config, ., ("tei-byline", css:map-rend-to-class(.)), .)
                    case element(table) return
                        fo:table($config, ., ("tei-table", css:map-rend-to-class(.)), .)
                    case element(group) return
                        fo:block($config, ., ("tei-group", css:map-rend-to-class(.)), .)
                    case element(cb) return
                        fo:break($config, ., ("tei-cb", css:map-rend-to-class(.)), ., 'column', @n)
                    case element(persName) return
                        if (parent::person) then
                            fo:inline($config, ., ("tei-persName1", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-persName2", "annotation", "annotation-person", "authority", css:map-rend-to-class(.)), .)
                    case element(placeName) return
                        if (ancestor::place) then
                            fo:link($config, ., ("tei-placeName1", css:map-rend-to-class(.)), ., ancestor::place/ptr/@target, map {"target": '_blank'})
                        else
                            fo:inline($config, ., ("tei-placeName2", "annotation", "annotation-place", "authority", css:map-rend-to-class(.)), .)
                    case element(term) return
                        fo:inline($config, ., ("tei-term", "annotation", "annotation-term", "authority", css:map-rend-to-class(.)), .)
                    case element(orgName) return
                        fo:inline($config, ., ("tei-orgName", "annotation", "annotation-organization", "authority", css:map-rend-to-class(.)), .)
                    case element(place) return
                        (
                            fo:heading($config, ., ("tei-place1", css:map-rend-to-class(.)), placeName[@type="full"], 3),
                            if (placeName[not(@type)]) then
                                fo:heading($config, ., ("tei-place2", css:map-rend-to-class(.)), string-join(placeName[not(@type)]/string(), '; '), 4)
                            else
                                (),
                            fo:paragraph($config, ., ("tei-place3", css:map-rend-to-class(.)), string-join((country, region), ', ')),
                            fo:block($config, ., ("tei-place4", css:map-rend-to-class(.)), note/node())
                        )

                    case element(rs) return
                        if (@type='abbreviation') then
                            fo:inline($config, ., ("tei-rs1", "annotation", "annotation-abbreviation", css:map-rend-to-class(.)), .)
                        else
                            fo:inline($config, ., ("tei-rs2", css:map-rend-to-class(.)), .)
                    case element(person) return
                        (
                            fo:heading($config, ., ("tei-person1", css:map-rend-to-class(.)), persName[@type="full"], 3),
                            fo:block($config, ., ("tei-person2", css:map-rend-to-class(.)), string-join(occupation, ', ')),
                            fo:paragraph($config, ., ("tei-person3", css:map-rend-to-class(.)), ./note/node())
                        )

                    case element(app) return
                        let $params := 
                            map {
                                "lem": lem[1]/node(),
                                "rdg": string-join(  for $rdg at $p in ./rdg return (      '"rdg[' || $p || ']":"' || $rdg/string() || '"',         '"wit[' || $p || ']":"' || $rdg/@wit/string() || '"'     ),     ',' ),
                                "content": .
                            }

                                                let $content := 
                            model:template-app($config, ., $params)
                        return
                                                fo:pass-through(map:merge(($config, map:entry("template", true()))), ., ("tei-app", css:map-rend-to-class(.)), $content)
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
                    fo:escapeChars(.)
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

