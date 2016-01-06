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
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css" at "css.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $pmf:WORKING_DIR := system:get-exist-home() || "/webapp";
declare variable $pmf:IMAGE_DIR := $pmf:WORKING_DIR || "/WEB-INF/data/expathrepo/tei-simple-0.2/test/";

declare function pmf:paragraph($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-content($config, $node, $class, $content),
    "&#10;&#10;"
};

declare function pmf:heading($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $level := if ($content instance of node()) then max((count($content/ancestor::tei:div), 1)) else 1
    return
        switch ($level)
            case 1 return
                let $heading := normalize-space(pmf:get-content($config, $node, $class, $content))
                return
                    "\chapter*{" || $heading || " \markboth{" || $heading || "}{" || $heading || "}}&#10;"
            case 2 return
                "\section*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
            case 3 return
                "\subsection*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
            case 4 return
                "\subsubsection*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
            case 5 return
                "\paragraph*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
            case 6 return
                "\subparagraph*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
            default return
                "\section*{" || pmf:get-content($config, $node, $class, $content) || "}&#10;"
};

declare function pmf:list($config as map(*), $node as element(), $class as xs:string+, $content) {
    if ($node/tei:label) then 
        let $max := max($node/tei:label ! string-length(.))
        let $longest := ($node/tei:label[string-length(.) = $max])[1]/string()
        return (
            "\begin{description}[" || pmf:escapeChars($longest) || "]&#10;",
            $config?apply($config, $content),
            "\end{description}&#10;"
        )
    else
        switch($node/@type)
            case "ordered" return (
                "\begin{enumerate}&#10;",
                $config?apply($config, $content),
                "\end{enumerate}&#10;"
            )
            default return (
                "\begin{itemize}&#10;",
                $config?apply($config, $content),
                "\end{itemize}&#10;"
            )
};

declare function pmf:listItem($config as map(*), $node as element(), $class as xs:string+, $content) {
    if ($node/preceding-sibling::tei:label) then
        "\item[" || pmf:get-content($config, $node, $class, $node/preceding-sibling::tei:label[1]) || "] " ||
        pmf:get-content($config, $node, $class, $content) || "&#10;"
    else
        "\item " || pmf:get-content($config, $node, $class, $content) || "&#10;"
};

declare function pmf:block($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-content($config, $node, $class, $content),
    "&#10;&#10;"
};

declare function pmf:section($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-content($config, $node, $class, $content)
};

declare function pmf:anchor($config as map(*), $node as element(), $class as xs:string+, $content, $id as item()*) {
    "\label{" || $id || "}"
};

declare function pmf:link($config as map(*), $node as element(), $class as xs:string+, $content, $link as xs:anyURI?) {
    if (starts-with($link, "#")) then
        ("\hyperlink{", pmf:escapeChars(substring-after($link, "#")), "}{", pmf:get-content($config, $node, $class, $content), "}")
    else
        ("\hyperlink{", pmf:escapeChars($link), "}{", pmf:get-content($config, $node, $class, $content), "}")
};

declare function pmf:glyph($config as map(*), $node as element(), $class as xs:string+, $content as xs:anyURI?) {
    if ($content = "char:EOLhyphen") then
        "&#xAD;"
    else
        ()
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string+, $content, $url as xs:anyURI,
    $width, $height, $scale, $title) {
    let $w := if ($width and not(ends-with($width, "%"))) then "width=" || $width else ()
    let $h := if ($height and not(ends-with($height, "%"))) then "height=" || $height else ()
    let $s := if ($scale) then "scale=" || $scale else ()
    let $options := string-join(($w, $h, $s), ",")
    let $cmd :=
        if ($options) then
            "\includegraphics[" || $options || "]{" || $url || "}"
        else
            "\includegraphics{" || $url || "}"
    return
        $cmd
};

declare function pmf:inline($config as map(*), $node as element(), $class as xs:string+, $content as item()*) {
    pmf:get-content($config, $node, $class, $content)
};

declare function pmf:text($config as map(*), $node as element(), $class as xs:string+, $content as item()*) {
    pmf:escapeChars(string-join($content))
};

declare function pmf:cit($config as map(*), $node as element(), $class as xs:string+, $content as node()*) {
    pmf:inline($config, $node, $class, $content)
};

declare function pmf:body($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-content($config, $node, $class, $content)
};

declare function pmf:omit($config as map(*), $node as element(), $class as xs:string+, $content) {
    ()
};

declare function pmf:index($config as map(*), $node as element(), $class as xs:string+, $content, $type as xs:string) {
    ()
};

declare function pmf:break($config as map(*), $node as element(), $class as xs:string+, $content, $type as xs:string, $label as item()*) {
    switch($type)
        case "page" return
            ()
        default return
            "\\"
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $odd := doc($config?odd)
    let $config := pmf:load-styles($config, $odd)
    return (
        "\documentclass[11pt]{book}&#10;",
(:        "\usepackage[utf8]{inputenc}&#10;",:)
        "\usepackage[english]{babel}&#10;",
        "\usepackage{colortbl}&#10;",
        "\usepackage{fancyhdr}&#10;",
        "\usepackage{xcolor}&#10;",
        "\usepackage[normalem]{ulem}&#10;",
        "\usepackage{marginfix}&#10;",
        "\usepackage[a4paper, twoside, top=25mm, bottom=35mm, outer=40mm, inner=20mm, heightrounded, marginparwidth=25mm, marginparsep=5mm]{geometry}&#10;",
        "\usepackage{graphicx}&#10;",
        "\usepackage{hyperref}&#10;",
        "\usepackage{ifxetex}&#10;",
        "\usepackage{longtable}&#10;",
        "\usepackage[maxfloats=64]{morefloats}&#10;",
        "\usepackage{listings}&#10;",
        "\lstset{&#10;",
        "basicstyle=\small\ttfamily,",
        "columns=flexible,",
        "breaklines=true",
        "}&#10;",
        "\pagestyle{fancy}&#10;",
        "\fancyhf{}&#10;",
        "\def\theendnote{\@alph\c@endnote}&#10;",
        "\def\Gin@extensions{.pdf,.png,.jpg,.mps,.tif}&#10;",
        "\hyperbaseurl{}&#10;",
        if (exists($config?image-dir)) then
            "\graphicspath{" || 
            string-join(
                for $dir in $config?image-dir return "{" || $dir || "}"
            ) ||
            "}&#10;"
        else
            (),
        "\def\tableofcontents{\section*{\contentsname}\@starttoc{toc}}&#10;",
        "\thispagestyle{empty}&#10;",
        "\begin{document}&#10;",
        "\mainmatter&#10;",
        "\fancyhead[EL,OR]{\thepage}&#10;",
        "\fancyhead[ER]{\leftmark}&#10;",
        "\fancyhead[OL]{\leftmark}&#10;",
        $config?apply-children($config, $node, $content),
        "\end{document}"
    )
};

declare function pmf:metadata($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $fileDesc := $node//tei:fileDesc
    let $titleStmt := $fileDesc/tei:titleStmt
    let $editionStmt := $fileDesc/tei:editionStmt
    return (
        "\title{" || pmf:get-content($config, $node, $class, $titleStmt/tei:title) || "}&#10;",
        "\author{" || string-join($titleStmt/tei:author ! pmf:escapeChars(.), " \and ") || "}&#10;",
        "\date{" || pmf:escapeChars($editionStmt/tei:edition) || "}&#10;",
        "\maketitle&#10;"
    )
};

declare function pmf:title($config as map(*), $node as element(), $class as xs:string+, $content) {
    "\title{", pmf:get-content($config, $node, $class, $content), "}&#10;"
};

declare function pmf:table($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $cols := max($node/tei:row ! count(tei:cell))
    return
        "\begin{longtable}{" || string-join((1 to $cols) ! "l", "l") || "}&#10;",
        $config?apply-children($config, $node, $content),
        "\end{longtable}&#10;"
};

declare function pmf:row($config as map(*), $node as element(), $class as xs:string+, $content) {
    $config?apply-children($config, $node, $content), " \\&#10;"
};

declare function pmf:cell($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-content($config, $node, $class, $content),
    (if ($node/following-sibling::*) then " &amp; " else ())
};

declare function pmf:alternate($config as map(*), $node as element(), $class as xs:string+, $content, $default as node()*,
    $alternate as node()*) {
    pmf:get-content($config, $node, $class, $default),
    "\footnote{", pmf:get-content($config, $node, $class, $alternate), "}"
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content as item()*, $place as xs:string?, $label as xs:string?) {
    switch($place)
        case "margin" return (
            "\marginpar{\noindent\raggedleft\footnotesize " || pmf:get-content($config, $node, $class, $content) || "}"
        )
        default return (
            "\footnote{" || pmf:get-content($config, $node, $class, $content) || "}"
        )
};

declare function pmf:escapeChars($text as xs:string?) {
    replace(
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
        ),
        "\s+", " "
    )
};

declare function pmf:get-content($config as map(*), $node as element(), $class as xs:string+, $content) {
    pmf:get-before($config, $class),
    pmf:check-styles($config, $class, $config?apply-children($config, $node, $content)),
    pmf:get-after($config, $class)
};

declare %private function pmf:get-before($config as map(*), $classes as xs:string+) {
    for $class in $classes
    let $before := $config?styles?($class || ":before")
    return
        if (exists($before)) then pmf:escapeChars($before?content) else ()
};

declare %private function pmf:get-after($config as map(*), $classes as xs:string+) {
    for $class in $classes
    let $after := $config?styles?($class || ":after")
    return
        if (exists($after)) then pmf:escapeChars($after?content) else ()
};

declare %private function pmf:check-styles($config as map(*), $classes as xs:string+, $content as item()*) {
    let $styles := map:new(for $class in $classes return $config?styles?($class))
    let $text := string-join($content)
    return
        if (exists($styles)) then
            pmf:style($styles?*, $styles, $text)
        else
            $text
};

declare %private function pmf:style($names as xs:string*, $styles as map(*), $text) {
    if (empty($names)) then
        $text
    else
        let $style := head($names)
        let $value := $styles($style)
        let $styled :=
            switch($style)
                case "font-weight" return
                    switch($value)
                        case "bold" return
                            "\textbf{" || $text || "}"
                        default return
                            $text
                case "font-style" return
                    switch($value)
                        case "italic" return
                            "\textit{" || $text || "}"
                        default return
                            $text
                case "font-variant" return
                    if ($value = "small-caps") then
                        "\sc{"  || $text || "}"
                    else
                        $text
                case "font-size" return
                    switch ($value)
                        case "small" case "smaller" return
                            "{\small " || $text || "}"
                        case "x-small" return
                            "{\footnotesize " || $text || "}"
                        case "xx-small" return
                            "{\tiny " || $text || "}"
                        case "large" case "larger" return
                            "{\large " || $text || "}"
                        case "x-large" return
                            "{\Large " || $text || "}"
                        default return
                            if (matches($value, "^\d+\w+$")) then
                                "{\fontsize{" || $value || "}{1.2em}\selectfont " || $text || "}"
                            else
                                $text
                case "color" return
                    if (matches($value, "#.{3}")) then
                        $text
                    else if (starts-with($value, "#")) then
                        "\textcolor[HTML]{" || substring-after($value, "#") || "}{" || $text || "}"
                    else
                        "\textcolor{" || $value || "}{" || $text || "}"
                case "text-decoration" return
                    if ($value = "underline") then
                        "\underline{" || $text || "}"
                    else if ($value = "line-through") then
                        "\sout{" || $text || "}"
                    else
                        $text
                case "text-align" return
                    switch ($value)
                        case "left" return
                            "{\raggedleft " || $text || "}"
                        case "right" return
                            "{\raggedright " || $text || "}"
                        case "center" return
                            "{\centering " || $text || "}"
                        default return
                            $text
                default return
                    $text
        return
            pmf:style(tail($names), $styles, $styled)
};

declare function pmf:load-styles($config as map(*), $root as document-node()) {
    let $css := css:generate-css($root)
    let $styles := css:parse-css($css)
    return
        map:new(($config, map:entry("styles", $styles)))
};