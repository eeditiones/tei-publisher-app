xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-latex";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex" at "../content/latex-functions.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:code($config as map(*), $node as element(), $class as xs:string, $content as node()*, $lang as item()?) {
    "\begin{verbatim}" || latex:get-content($config, $node, $class, $content) || "\end{verbatim}&#10;"
};

declare function pmf:frame($config as map(*), $node as element(), $class as xs:string+, $content) {
    "\begin{frame}&#10;" || latex:get-content($config, $node, $class, $content) || "&#10;\end{frame}&#10;"
};

declare function pmf:beamer-block($config as map(*), $node as element(), $class as xs:string+, $type, $content, $heading) {
    "\begin{", $type, "}{", 
    $config?apply-children($config, $node, $heading/node()),
    "}&#10;",
    latex:get-content($config, $node, $class, $content),
    "&#10;\end{", $type, "}&#10;"
};

declare function pmf:frametitle($config as map(*), $node as element(), $class as xs:string+, $content) {
    "\frametitle{" || latex:get-content($config, $node, $class, $content) || "}&#10;"
};

declare function pmf:beamer-document($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $odd := doc($config?odd)
    let $config := latex:load-styles($config, $odd)
    return (
        "\documentclass{beamer}&#10;",
        "\usepackage[utf8]{inputenc}&#10;",
        "\usepackage[english]{babel}&#10;",
        "\usepackage{colortbl}&#10;",
        "\usepackage{xcolor}&#10;",
        "\usepackage[normalem]{ulem}&#10;",
        "\usepackage{graphicx}&#10;",
        "\usepackage{hyperref}&#10;",
        "\usepackage{longtable}&#10;",
        "\usetheme{AnnArbor}&#10;",
        "\usecolortheme{beaver}&#10;",
        "\begin{document}&#10;",
        $config?apply-children($config, $node, $content),
        "\end{document}"
    )
};