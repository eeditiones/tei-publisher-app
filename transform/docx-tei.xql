(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docx.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docx/tei";

declare default element namespace "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace a='http://schemas.openxmlformats.org/drawingml/2006/main';

declare namespace pb='http://teipublisher.com/1.0';

declare namespace r='http://schemas.openxmlformats.org/officeDocument/2006/relationships';

declare namespace v='urn:schemas-microsoft-com:vml';

declare namespace w='http://schemas.openxmlformats.org/wordprocessingml/2006/main';

declare namespace rel='http://schemas.openxmlformats.org/package/2006/relationships';

declare namespace dcterms='http://purl.org/dc/terms/';

declare namespace pic='http://schemas.openxmlformats.org/drawingml/2006/picture';

declare namespace cp='http://schemas.openxmlformats.org/package/2006/metadata/core-properties';

declare namespace dc='http://purl.org/dc/elements/1.1/';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace tei="http://existsolutions.com/xquery/functions/tei";

import module namespace ext-docx="http://www.tei-c.org/tei-simple/xquery/functions/docx";

import module namespace global="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";

(: generated template function for element spec: r :)
declare %private function model:template-r6($config as map(*), $node as node()*, $params as map(*)) {
    <persName xmlns="http://www.tei-c.org/ns/1.0" ref="http://d-nb.info/gnd/{$config?apply-children($config, $node, $params?ref)}">{$config?apply-children($config, $node, $params?content)}</persName>
};
(: generated template function for element spec: r :)
declare %private function model:template-r11($config as map(*), $node as node()*, $params as map(*)) {
    <hi xmlns="http://www.tei-c.org/ns/1.0" rend="{$config?apply-children($config, $node, $params?rend)}">{$config?apply-children($config, $node, $params?content)}</hi>
};
(: generated template function for element spec: cp:coreProperties :)
declare %private function model:template-cp_coreProperties($config as map(*), $node as node()*, $params as map(*)) {
    <fileDesc xmlns="http://www.tei-c.org/ns/1.0">
  <titleStmt>
    <title>{$config?apply-children($config, $node, $params?title)}</title>
    {$config?apply-children($config, $node, $params?author)}
  </titleStmt>
  <publicationStmt>
    <p>Information about publication or distribution</p>
  </publicationStmt>
  <sourceDesc>
    <p>Information about the source</p>
  </sourceDesc>
</fileDesc>
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["tei"],
                "odd": "/db/apps/tei-publisher/odd/docx.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    
    return (
        
        let $output := model:apply($config, $input)
        return
            ext-docx:finish($config, $output)
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
                    case element(body) return
                        tei:body($config, ., ("tei-body", css:map-rend-to-class(.)), .)
                    case element(p) return
                        if ($parameters?pstyle(.)/name[starts-with(@w:val, 'tei:')]) then
                            tei:inline($config, ., ("tei-p1", css:map-rend-to-class(.)), ., map {"tei_element": substring-after($parameters?pstyle(.)/name/@w:val, 'tei:')})
                        else
                            if ($parameters?pstyle(.)/name[matches(@w:val, "quote$", "i")]) then
                                tei:cit($config, ., ("tei-p2", css:map-rend-to-class(.)), ., ())
                            else
                                if ($parameters?nstyle(.)/numFmt) then
                                    tei:listItem($config, ., ("tei-p3", css:map-rend-to-class(.)), ., (), map {"level": $parameters?nstyle(.)/@w:ilvl, "type": if ($parameters?nstyle(.)/numFmt[@w:val = 'bullet']) then  () else  'ordered'})
                                else
                                    if ($parameters?pstyle(.)/name[matches(@w:val, "^title", "i")]) then
                                        (: The default "title" style gets level 0 assigned :)
                                        tei:heading($config, ., ("tei-p4", css:map-rend-to-class(.)), ., 0)
                                    else
                                        if ($parameters?pstyle(.)/name[matches(@w:val, "^(heading|subtitle)", "i")]) then
                                            tei:heading($config, ., ("tei-p5", css:map-rend-to-class(.)), ., let $l := $parameters?pstyle(.)//outlineLvl/@w:val return  if ($l) then $l/number() + 1 else 1)
                                        else
                                            tei:paragraph($config, ., ("tei-p6", css:map-rend-to-class(.)), .)
                    case element(r) return
                        if (drawing) then
                            tei:inline($config, ., ("tei-r1", css:map-rend-to-class(.)), .//pic:pic, map {})
                        else
                            if (ancestor::w:footnote and $parameters?cstyle(.)/name/@w:val = 'footnote reference') then
                                (: Omit footnote characters inside the footnote text itself :)
                                tei:omit($config, ., ("tei-r2", css:map-rend-to-class(.)), .)
                            else
                                if (footnoteReference[@w:customMarkFollows]) then
                                    (: Footnote reference with a custom mark is encoded with type=original :)
                                    tei:note($config, ., ("tei-r3", css:map-rend-to-class(.)), $parameters?footnote(.), 'footnote', w:t, map {"type": 'original'})
                                else
                                    if (footnoteReference) then
                                        tei:note($config, ., ("tei-r4", css:map-rend-to-class(.)), $parameters?footnote(.), 'footnote', w:t, map {})
                                    else
                                        if (endnoteReference) then
                                            tei:note($config, ., ("tei-r5", css:map-rend-to-class(.)), $parameters?endnote(.), 'endnote', (), map {})
                                        else
                                            if ($parameters?cstyle(.)/name[@w:val = 'tei:persName'] and matches(., '&#60;.*&#62;')) then
                                                (: Example for encoding @ref attached to a tei:persName element using a convention. Content between angle brackets will be stripped by post-processing :)
                                                let $params := 
                                                    map {
                                                        "ref": replace(., '^.*?&#60;(.*)&#62;.*$', '$1'),
                                                        "content": .
                                                    }

                                                                                                let $content := 
                                                    model:template-r6($config, ., $params)
                                                return
                                                                                                tei:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-r6", css:map-rend-to-class(.)), $content, map {"ref": replace(., '^.*?&#60;(.*)&#62;.*$', '$1')})
                                            else
                                                if ($parameters?cstyle(.)/name[@w:val = 'tei:code']) then
                                                    (: tei:code may contain angle brackets, so needs to be handled separately :)
                                                    tei:inline($config, ., ("tei-r7", css:map-rend-to-class(.)), ., map {"tei_element": 'code', "tei_attributes": ()})
                                                else
                                                    if ($parameters?cstyle(.)/name[@w:val = 'tei:tag']) then
                                                        (: tei:tag may contain angle brackets, so needs to be handled separately :)
                                                        tei:inline($config, ., ("tei-r8", css:map-rend-to-class(.)), ., map {"tei_element": 'tag'})
                                                    else
                                                        if ($parameters?cstyle(.)/name[starts-with(@w:val, 'tei:')] and matches(., '&#60;.*=.*&#62;')) then
                                                            (: Character style starts with 'tei:' and has parameters in content, which will be interpreted as attribute list :)
                                                            tei:inline($config, ., ("tei-r9", css:map-rend-to-class(.)), ., map {"tei_element": substring-after($parameters?cstyle(.)/name/@w:val, 'tei:'), "tei_attributes": tokenize(replace(., '^.*?&#60;(.*)&#62;.*$', '$1'), '\s*;\s*')})
                                                        else
                                                            if ($parameters?cstyle(.)/name[starts-with(@w:val, 'tei:')]) then
                                                                tei:inline($config, ., ("tei-r10", css:map-rend-to-class(.)), ., map {"tei_element": substring-after($parameters?cstyle(.)/name/@w:val, 'tei:')})
                                                            else
                                                                if (rPr/(u|i|caps|b|strike) or $parameters?cstyle(.)/rPr/(u|i|caps|b|strike)) then
                                                                    let $params := 
                                                                        map {
                                                                            "rend": (rPr/(u|i|caps|b|strike), $parameters?cstyle(.)/rPr/(u|i|caps|b|strike)) ! local-name(.),
                                                                            "content": .
                                                                        }

                                                                                                                                        let $content := 
                                                                        model:template-r11($config, ., $params)
                                                                    return
                                                                                                                                        tei:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-r11", css:map-rend-to-class(.)), $content, map {"rend": (rPr/(u|i|caps|b|strike), $parameters?cstyle(.)/rPr/(u|i|caps|b|strike)) ! local-name(.)})
                                                                else
                                                                    tei:inline($config, ., ("tei-r12", css:map-rend-to-class(.)), ., map {})
                    case element(document) return
                        tei:document($config, ., ("tei-document", css:map-rend-to-class(.)), ($parameters?properties, .))
                    case element(bookmarkStart) return
                        if (not(starts-with(@w:name, 'OLE') or @w:name='_GoBack')) then
                            tei:anchor($config, ., ("tei-bookmarkStart", css:map-rend-to-class(.)), ., @w:name, map {})
                        else
                            $config?apply($config, ./node())
                    case element(hyperlink) return
                        if (@w:anchor) then
                            tei:link($config, ., ("tei-hyperlink1", css:map-rend-to-class(.)), ., '#' || @w:anchor, ())
                        else
                            tei:link($config, ., ("tei-hyperlink2", css:map-rend-to-class(.)), ., $parameters?link(.)/@Target/string(), ())
                    case element(cp:coreProperties) return
                        let $params := 
                            map {
                                "title": if (dc:title/node()) then dc:title else replace(util:collection-name(.), '^.*?/([^/]+)/docProps.*$', '$1'),
                                "author": dc:creator,
                                "content": .
                            }

                                                let $content := 
                            model:template-cp_coreProperties($config, ., $params)
                        return
                                                tei:metadata(map:merge(($config, map:entry("template", true()))), ., ("tei-cp_coreProperties", css:map-rend-to-class(.)), $content)
                    case element(dc:title) return
                        tei:inline($config, ., ("tei-dc_title", css:map-rend-to-class(.)), ., map {})
                    case element(dc:creator) return
                        tei:inline($config, ., ("tei-dc_creator", css:map-rend-to-class(.)), ., map {"tei_element": 'author'})
                    case element(tbl) return
                        tei:table($config, ., ("tei-tbl", css:map-rend-to-class(.)), tr)
                    case element(tr) return
                        tei:row($config, ., ("tei-tr", css:map-rend-to-class(.)), tc)
                    case element(tc) return
                        tei:cell($config, ., ("tei-tc", css:map-rend-to-class(.)), p, (), map {"cols": tcPr/gridSpan/@w:val})
                    case element(t) return
                        tei:text($config, ., ("tei-t", css:map-rend-to-class(.)), .)
                    case element(pic:pic) return
                        tei:graphic($config, ., ("tei-pic_pic", css:map-rend-to-class(.)), ., let $id := .//a:blip/@r:embed  let $mediaColl := $parameters?filename || ".media/"  let $target := $parameters?rels/rel:Relationship[@Id=$id]/@Target return  $mediaColl || substring-after($target, "media/"), (), (), (), ())
                    case element(smartTag) return
                        tei:inline($config, ., ("tei-smartTag", css:map-rend-to-class(.)), ., map {})
                    case element(pict) return
                        tei:inline($config, ., ("tei-pict", css:map-rend-to-class(.)), .//v:imagedata, map {})
                    case element(v:imagedata) return
                        tei:graphic($config, ., ("tei-v_imagedata", css:map-rend-to-class(.)), ., let $id := @r:id let $mediaColl := $parameters?filename || ".media/"  let $relationship := $parameters?rels/rel:Relationship[@Id=$id] let $target := $relationship/@Target return  if ($relationship/@TargetMode = "External") then      $target     else   $mediaColl || substring-after($target, "media/"), (), (), (), ())
                    case element(commentRangeStart) return
                        tei:anchor($config, ., ("tei-commentRangeStart", css:map-rend-to-class(.)), ., 'ac'||@w:id, map {"type": 'note'})
                    case element(commentRangeEnd) return
                        tei:note($config, ., ("tei-commentRangeEnd", css:map-rend-to-class(.)), $parameters?comment(.), 'footnote', (), map {"target": 'ac' || @w:id})
                    case element() return
                        tei:omit($config, ., ("tei--element", css:map-rend-to-class(.)), .)
                    case text() | xs:anyAtomicType return
                        tei:escapeChars(.)
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
                    tei:escapeChars(.)
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

