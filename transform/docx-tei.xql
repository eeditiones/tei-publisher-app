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

(: generated template function for element spec: r :)
declare %private function model:template-r5($config as map(*), $node as node()*, $params as map(*)) {
    <hi xmlns="http://www.tei-c.org/ns/1.0" rend="underline">{$config?apply-children($config, $node, $params?content)}</hi>
};
(: generated template function for element spec: r :)
declare %private function model:template-r6($config as map(*), $node as node()*, $params as map(*)) {
    <hi xmlns="http://www.tei-c.org/ns/1.0" rend="bold">{$config?apply-children($config, $node, $params?content)}</hi>
};
(: generated template function for element spec: r :)
declare %private function model:template-r7($config as map(*), $node as node()*, $params as map(*)) {
    <hi xmlns="http://www.tei-c.org/ns/1.0">{$config?apply-children($config, $node, $params?content)}</hi>
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
            tei:finish($config, $output)
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
                    case element(body) return
                        tei:body($config, ., ("tei-body"), .)
                    case element(p) return
                        if ($parameters?pstyle(.)/name[matches(@w:val, "quote$", "i")]) then
                            tei:cit($config, ., ("tei-p1"), ., ())
                        else
                            if ($parameters?nstyle(.)/numFmt) then
                                tei:listItem($config, ., ("tei-p2"), ., (), map {"level": $parameters?nstyle(.)/@w:ilvl, "type": if ($parameters?nstyle(.)/numFmt[@w:val = 'bullet']) then  () else  'ordered'})
                            else
                                if ($parameters?pstyle(.)/name[matches(@w:val, "^(heading|title|subtitle)", "i")]) then
                                    tei:heading($config, ., ("tei-p3"), ., let $l := $parameters?pstyle(.)//outlineLvl/@w:val return  if ($l) then $l/number() + 1 else 0)
                                else
                                    tei:paragraph($config, ., ("tei-p4"), .)
                    case element(r) return
                        if (drawing) then
                            tei:inline($config, ., ("tei-r1"), .//pic:pic, map {})
                        else
                            if (footnoteReference) then
                                tei:note($config, ., ("tei-r2"), $parameters?footnote(.), 'footnote', ())
                            else
                                if (endnoteReference) then
                                    tei:note($config, ., ("tei-r3"), $parameters?endnote(.), 'endnote', ())
                                else
                                    if ($parameters?cstyle(.)/name[starts-with(@w:val, 'tei:')]) then
                                        tei:inline($config, ., ("tei-r4"), ., map {"tei_element": substring-after($parameters?cstyle(.)/name/@w:val, 'tei:')})
                                    else
                                        if (rPr/u or $parameters?cstyle(.)/rPr/u) then
                                            let $params := 
                                                map {
                                                    "content": .
                                                }

                                                                                        let $content := 
                                                model:template-r5($config, ., $params)
                                            return
                                                                                        tei:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-r5"), $content, map {})
                                        else
                                            if (rPr/b or $parameters?cstyle(.)/rPr/b) then
                                                let $params := 
                                                    map {
                                                        "content": .
                                                    }

                                                                                                let $content := 
                                                    model:template-r6($config, ., $params)
                                                return
                                                                                                tei:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-r6"), $content, map {})
                                            else
                                                if (rPr/(i|caps) or $parameters?cstyle(.)/rPr/(i|caps)) then
                                                    let $params := 
                                                        map {
                                                            "content": .
                                                        }

                                                                                                        let $content := 
                                                        model:template-r7($config, ., $params)
                                                    return
                                                                                                        tei:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-r7"), $content, map {})
                                                else
                                                    tei:inline($config, ., ("tei-r8"), ., map {})
                    case element(document) return
                        tei:document($config, ., ("tei-document"), ($parameters?properties, .))
                    case element(bookmarkStart) return
                        tei:anchor($config, ., ("tei-bookmarkStart"), ., @w:name)
                    case element(hyperlink) return
                        if (@w:anchor) then
                            tei:link($config, ., ("tei-hyperlink1"), ., '#' || @w:anchor, ())
                        else
                            tei:link($config, ., ("tei-hyperlink2"), ., $parameters?link(.)/@Target/string(), ())
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
                                                tei:metadata(map:merge(($config, map:entry("template", true()))), ., ("tei-cp:coreProperties"), $content)
                    case element(dc:title) return
                        tei:inline($config, ., ("tei-dc:title"), ., map {})
                    case element(dc:creator) return
                        tei:inline($config, ., ("tei-dc:creator"), ., map {"tei_element": 'author'})
                    case element(tbl) return
                        tei:table($config, ., ("tei-tbl"), tr)
                    case element(tr) return
                        tei:row($config, ., ("tei-tr"), tc)
                    case element(tc) return
                        tei:cell($config, ., ("tei-tc"), p, (), map {"cols": tcPr/gridSpan/@w:val})
                    case element(t) return
                        tei:text($config, ., ("tei-t"), .)
                    case element(pic:pic) return
                        tei:graphic($config, ., ("tei-pic:pic"), ., let $id := .//a:blip/@r:embed  let $mediaColl := $parameters?filename || ".media/"  let $target := $parameters?rels/rel:Relationship[@Id=$id]/@Target return  $mediaColl || substring-after($target, "media/"), (), (), (), ())
                    case element(smartTag) return
                        tei:inline($config, ., ("tei-smartTag"), ., map {})
                    case element(pict) return
                        tei:inline($config, ., ("tei-pict"), .//v:imagedata, map {})
                    case element(v:imagedata) return
                        tei:graphic($config, ., ("tei-v:imagedata"), ., let $id := @r:id let $mediaColl := $parameters?filename || ".media/"  let $relationship := $parameters?rels/rel:Relationship[@Id=$id] let $target := $relationship/@Target return  if ($relationship/@TargetMode = "External") then      $target     else   $mediaColl || substring-after($target, "media/"), (), (), (), ())
                    case element() return
                        tei:omit($config, ., ("tei--element"), .)
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

