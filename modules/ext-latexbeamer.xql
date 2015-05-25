xquery version "3.0";

module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-latexbeamer";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex" at "../content/latex-functions.xql";

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

declare function pmf:alert($config as map(*), $node as element(), $class as xs:string+, $content) {
    "\alert{" || latex:get-content($config, $node, $class, $content) || "}"
};

declare function pmf:graphic($config as map(*), $node as element(), $class as xs:string+, $content, $url as xs:anyURI,
    $width, $height, $scale, $title) {
    "\begin{center}&#10;",
    "\includegraphics[width=\textwidth,height=0.8\textheight,keepaspectratio]{" || $url || "}",
    "\end{center}&#10;"
};

declare function pmf:document($config as map(*), $node as element(), $class as xs:string+, $content) {
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
        "\usetheme{Boadilla}&#10;",
        "\usecolortheme{seahorse}&#10;",
        if (exists($config?image-dir)) then
            "\graphicspath{" || 
            string-join(
                for $dir in $config?image-dir return "{" || $dir || "}"
            ) ||
            "}&#10;"
        else
            (),
        "\begin{document}&#10;",
        $config?apply-children($config, $node, $content),
        "\end{document}"
    )
};