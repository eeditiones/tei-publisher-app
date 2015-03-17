xquery version "3.1";

(:~
 : Function module to produce HTML output. The functions defined here are called 
 : from the generated XQuery transformation module. Function names must match
 : those of the corresponding TEI Processing Model functions.
 : 
 : @author Wolfgang Meier
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/fo";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace console="http://exist-db.org/xquery/console";

declare variable $pmf:DEFAULT_HEADINGS :=
    [[36, 44, "normal"], [24, 29, "normal"], [18, 22, "normal"], [11, 16, "bold"]];

declare variable $pmf:CSS_PROPERTIES := (
    "font-family", 
    "font-weight",
    "font-style",
    "font-variant",
    "text-align", 
    "text-decoration",
    "line-height",
    "color",
    "background-color"
);

declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <fo:block text-align="left" text-indent="2em" hyphenate="true">{pmf:apply-children($config, $node, $content)}</fo:block>
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string, $content as node()*, $type, $subdiv) {
    let $parent := local-name($content/..)
    let $level := count($content/ancestor::*[local-name(.) = $parent])
    let $defaults :=
        if ($level < 5) then
            $pmf:DEFAULT_HEADINGS($level + 1)
        else
            $pmf:DEFAULT_HEADINGS(array:size($pmf:DEFAULT_HEADINGS))
    return
        <fo:block font-size="{$defaults?1}pt" space-after="{$defaults?2}pt"
            space-before="{$defaults?2}pt"
            keep-with-next.within-page="always" line-height="{$defaults?2}pt"
            font-weight="{$defaults?3}">
            {pmf:apply-children($config, $node, $content)}
        </fo:block>
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    let $label-length :=
        if ($node/tei:label) then
            max($node/tei:label ! string-length(.))
        else
            1
    return
        <fo:list-block provisional-distance-between-starts="{$label-length}em">
            {$config?apply($config, $content)}
        </fo:list-block>
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <fo:list-item>
        <fo:list-item-label><fo:block/></fo:list-item-label>
        <fo:list-item-body start-indent="body-start()">
            <fo:block>{pmf:apply-children($config, $node, $content)}</fo:block>
        </fo:list-item-body>
    </fo:list-item>
};

declare function pmf:block($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    <fo:block text-align="left" text-indent="2em" hyphenate="true">
    {pmf:apply-children($config, $node, $content)}
    </fo:block>
};

declare function pmf:section($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string, $id as item()*) {
    ()
};

declare function pmf:link($config as map(*), $node as element(), $class as xs:string, $content as node()*, $url as xs:anyURI?) {
    if (starts-with($url, "#")) then
        <fo:basic-link internal-destination="{substring-after($url, '#')}">
        {pmf:apply-children($config, $node, $content)}
        </fo:basic-link>
    else
        <fo:basic-link external-destination="{$url}">{pmf:apply-children($config, $node, $content)}</fo:basic-link>
};

declare function pmf:escapeChars($text as xs:string) {
    $text
};

declare function pmf:glyph($config as map(*), $node as element(), $class as xs:string, $content as xs:anyURI?) {
    if ($content = "char:EOLhyphen") then
        "&#xAD;"
    else
        ()
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string, $url as xs:anyURI,
    $width, $height, $scale) {
    let $style := if ($width) then "width: " || $width || "; " else ()
    let $style := if ($height) then $style || "height: " || $height || "; " else $style
    return
        <img src="{$url}">
        { if ($style) then attribute style { $style } else () }
        </img>
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    <fo:inline>
    {
        pmf:check-styles($config, $class),
        pmf:apply-children($config, $node, $content)
    }
    </fo:inline>
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    string($content)
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:inline($config, $node, $class, $content)
};

declare function pmf:body($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:index($config as map(*), $node as element(), $class as xs:string, $content as node()*, $type as xs:string) {
    ()
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string, $type as xs:string, $label as item()*) {
    <fo:block/>
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    let $odd := doc($config?odd)
    let $config := pmf:load-styles($config, $odd)
    let $log := console:log(serialize($config?styles, <output:serialization-parameters>
            <output:method>json</output:method>
            <output:indent>yes</output:indent>
        </output:serialization-parameters>))
    return
     <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
        <fo:layout-master-set>
            <fo:simple-page-master master-name="page-left" margin-top="10mm"
                    margin-bottom="10mm" margin-left="24mm"
                    margin-right="12mm" page-height="297mm" page-width="210mm">
                <fo:region-body margin-bottom="10mm" margin-top="16mm"/>
                <fo:region-before region-name="head-left" extent="10mm"/>
            </fo:simple-page-master>
            <fo:simple-page-master master-name="page-right" margin-top="10mm"
                    margin-bottom="10mm" margin-left="12mm"
                    margin-right="24mm" page-height="297mm" page-width="210mm">
                <fo:region-body margin-bottom="10mm" margin-top="16mm"/>
                <fo:region-before region-name="head-right" extent="10mm"/>
            </fo:simple-page-master>
            <fo:page-sequence-master master-name="page-content">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference 
                        master-reference="page-right" odd-or-even="odd"/>
                    <fo:conditional-page-master-reference 
                        master-reference="page-left" odd-or-even="even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
        </fo:layout-master-set>
        <fo:page-sequence master-reference="page-content">
            <fo:static-content flow-name="head-left">
                <fo:block margin-bottom="0.7mm" text-align-last="justify" font-family="serif"
                    font-size="10pt">
                    <fo:page-number/>
                    <fo:leader/>
                    <fo:retrieve-marker retrieve-class-name="heading"/>
                </fo:block>
            </fo:static-content>
            <fo:static-content flow-name="head-right">
                <fo:block margin-bottom="0.7mm" text-align-last="justify" font-family="serif"
                    font-size="10pt">
                    <fo:retrieve-marker retrieve-class-name="heading"/>
                    <fo:leader/>
                    <fo:page-number/>
                </fo:block>
            </fo:static-content>
            <!--fo:static-content flow-name="xsl-footnote-separator">
                <fo:block margin-top="4mm"/>
            </fo:static-content-->
            <fo:static-content flow-name="xsl-footnote-separator">
                <fo:block text-align-last="justify" margin-top="4mm" space-after="2mm">
                    <fo:leader leader-length="40%" rule-thickness="2pt" leader-pattern="rule" color="grey"/>
                </fo:block>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body" font-family="serif"
                font-size="11pt" line-height="16pt"
                xml:lang="sa" language="sa" hyphenate="true">
                {pmf:apply-children($config, $node, $content)}
            </fo:flow>                         
        </fo:page-sequence>
    </fo:root>
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    ()
};

declare function pmf:title($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    ()
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:alternate($config as map(*), $node as element(), $class as xs:string, $option1 as node()*,
    $option2 as node()*) {
    pmf:apply-children($config, $node, $option1)
};

declare function pmf:get-rendition($node as node()*, $class as xs:string) {
    let $rend := $node/@rendition
    return
        if ($rend) then
            if (starts-with($rend, "#")) then
                'document_' || substring-after(.,'#')
            else if (starts-with($rend,'simple:')) then
                translate($rend,':','_')
            else
                $rend
        else
            $class
};

declare function pmf:get-before($config as map(*), $class as xs:string) {
    let $before := $config?styles?($class || ":before")?content
    return
        if ($before) then <fo:inline>{$before}</fo:inline> else ()
};

declare function pmf:get-after($config as map(*), $class as xs:string) {
    let $after := $config?styles?($class || ":after")?content
    return
        if ($after) then <fo:inline>{$after}</fo:inline> else ()
};

declare function pmf:check-styles($config as map(*), $class as xs:string) {
    let $styles := $config?styles?($class)
    return
        if (exists($styles)) then
            for $style in $styles?*[. = $pmf:CSS_PROPERTIES]
            return
                attribute { $style } { $styles($style) }
        else
            ()
};

declare function pmf:load-styles($config as map(*), $root as document-node()) {
    let $css := pmf:generate-css($root)
    let $styles := pmf:parse-css($css)
    return
        map:new(($config, map:entry("styles", $styles)))
};

declare function pmf:parse-css($css as xs:string) {
    map:new(
        let $analyzed := analyze-string($css, "^\s*\.(.*?)\s*\{\s*(.*?)\s*\}", "m")
        for $match in $analyzed/fn:match
        let $selector := $match/fn:group[@nr = "1"]/string()
        let $styles := map:new(
            for $match in analyze-string($match/fn:group[@nr = "2"], "\s*(.*?)\s*\:\s*(.*?)\;")/fn:match
            return
                map:entry($match/fn:group[1]/string(), $match/fn:group[2]/string())
        )
        return
            map:entry($selector, $styles)
    )
};

declare function pmf:generate-css($root as document-node()) {
    string-join((
        for $rend in $root//tei:rendition[@xml:id][not(parent::tei:model)]
        return
            "&#10;.simple_" || $rend/@xml:id || " { " || 
            normalize-space($rend/string()) || " }",
        "&#10;",
        for $model in $root//tei:model[tei:rendition]
        let $spec := $model/ancestor::tei:elementSpec[1]
        let $count := count($spec//tei:model)
        for $rend in $model/tei:rendition
        let $className :=
            if ($count > 1) then
                $spec/@ident || count($model/preceding::tei:model[. >> $spec]) + 1
            else
                $spec/@ident/string()
        let $class :=
            if ($rend/@scope) then
                $className || ":" || $rend/@scope
            else
                $className
        return
            "&#10;." || $class || " { " ||
            normalize-space($rend) || " }"
    ))
};

declare %private function pmf:apply-children($config as map(*), $node as element(), $content as item()*) {
    $content ! (
        typeswitch(.)
            case element() return
                $config?apply($config, ./node())
            default return
                string(.)
    )
};

declare function pmf:escapeChars($text as xs:string) {
    $text
};