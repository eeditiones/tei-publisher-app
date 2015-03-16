xquery version "3.1";

(:~
 : Function module to produce LaTeX output. The functions defined here are called 
 : from the generated XQuery transformation module. Function names must match
 : those of the corresponding TEI Processing Model functions.
 : 
 : @author Wolfgang Meier
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/latex";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content),
    "&#10;"
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string, $content as node()*, $type, $subdiv) {
    let $parent := local-name($content/..)
    let $level := count($content/ancestor::*[local-name(.) = $parent])
    return
        if ($level < 3) then
            "\" || ((2 to $level) ! "sub") || "section{" || pmf:apply-children($config, $node, $content) || "}"
        else
            pmf:apply-children($config, $node, $content)
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    "\begin{itemize}",
    $config?apply($config, $content),
    "\end{itemize}"
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    "\item " || pmf:apply-children($config, $node, $content)
};

declare function pmf:block($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:section($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string, $id as item()*) {
    "\label{" || $id || "}"
};

declare function pmf:link($config as map(*), $node as element(), $class as xs:string, $content as node()*, $url as xs:anyURI?) {
    "\hyperlink{" || $url || "}{" || pmf:apply-children($config, $node, $content) || "}"
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
        ()
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string, $content as item()*) {
    pmf:escapeChars(string-join($content))
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:inline($config, $node, $class, $content)
};

declare function pmf:body($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string, $type as xs:string, $label as item()*) {
    "\linebreak"
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    "\documentclass[11pt]{article}",
    "\usepackage{colortbl}",
    "\usepackage{fancyhdr}",
    "\usepackage[a4paper,twoside,lmargin=1in,rmargin=1in,tmargin=1in,bmargin=1in,marginparwidth=0.75in]{geometry}",
    "\usepackage{graphicx}",
    "\usepackage{hyperref}",
    "\usepackage{ifxetex}",
    "\usepackage{longtable}",
    "\def\theendnote{\@alph\c@endnote}",
    "\def\Gin@extensions{.pdf,.png,.jpg,.mps,.tif}",
    "\pagestyle{fancy}",
    "\hyperbaseurl{}",
    "\paperwidth210mm",
    "\paperheight297mm",
    "\def\chaptername{Chapter}",
    "\def\tableofcontents{\section*{\contentsname}\@starttoc{toc}}",
    "\thispagestyle{empty}",
    "\begin{document}",
    pmf:apply-children($config, $node, $content),
    "\end{document}"
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content)
};

declare function pmf:title($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    "\title{" || pmf:apply-children($config, $node, $content) || "}"
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    "\begin{tabular}",
    pmf:apply-children($config, $node, $content),
    "\end{tabular}"
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content) || " \\"
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string, $content as node()*) {
    pmf:apply-children($config, $node, $content) ||
    (if ($node/following-sibling::*) then " &amp; " else ())
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

declare function pmf:generate-css($root as document-node()) {
    ()
};

declare %private function pmf:apply-children($config as map(*), $node as element(), $content as item()*) {
    string-join(
        $content ! (
            typeswitch(.)
                case element() return
                    $config?apply($config, ./node())
                case text() return
                    pmf:escapeChars(.)
                default return
                    pmf:escapeChars(.)
        ), "&#10;"
    )
};

declare function pmf:escapeChars($text as xs:string) {
    replace(
        replace(
            replace(
                replace(
                    replace($text, "\\", "\\textbackslash "),
                    '~','\\textasciitilde '
                ),
                '\^','\\textasciicircum '
            ),
            "_", "\\textunderscore "
        ),
        "([\}\{%&amp;\$#])", "\\$1"
    )
};