(:~

    Transformation module generated from TEI ODD extensions for processing models.
    ODD: /db/apps/tei-publisher/odd/docbook.odd
 :)
xquery version "3.1";

module namespace model="http://www.tei-c.org/pm/models/docbook/latex";

declare default element namespace "http://docbook.org/ns/docbook";

declare namespace xhtml='http://www.w3.org/1999/xhtml';

declare namespace pb='http://teipublisher.com/1.0';

declare namespace xlink='http://www.w3.org/1999/xlink';

import module namespace css="http://www.tei-c.org/tei-simple/xquery/css";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";

(: Code listing :)
declare %private function model:code($config as map(*), $node as node()*, $class as xs:string+, $content) {
    $node ! (
        let $language := @language
         let $code := replace($content, '^\s*(.*?)$', '$1')

        return

        ``[\begin{lstlisting}[language=`{string-join($config?apply-children($config, $node, $language))}`]
`{string-join($config?apply-children($config, $node, $code))}`
\end{lstlisting} ]``
    )
};

(: Generated behaviour function for ident definitionList :)
declare %private function model:definitionList($config as map(*), $node as node()*, $class as xs:string+, $content) {
    $node ! (

        
        ``[\begin{description}
`{string-join($config?apply-children($config, $node, $content))}`
\end{description}]``
    )
};

(: Generated behaviour function for ident definition :)
declare %private function model:definition($config as map(*), $node as node()*, $class as xs:string+, $content, $term) {
    $node ! (

        
        ``[\item [`{string-join($config?apply-children($config, $node, $term))}`] `{string-join($config?apply-children($config, $node, $content))}`]``
    )
};

(: Generated behaviour function for ident iframe :)
declare %private function model:iframe($config as map(*), $node as node()*, $class as xs:string+, $content, $src, $width, $height) {
    $node ! (

        
        <t xmlns=""><iframe src="{$config?apply-children($config, $node, $src)}" width="{$config?apply-children($config, $node, $width)}" height="{$config?apply-children($config, $node, $height)}" frameborder="0" gesture="media" allow="encrypted-media" allowfullscreen="allowfullscreen"> </iframe></t>/*
    )
};

(: generated template function for element spec: article :)
declare %private function model:template-article($config as map(*), $node as node()*, $params as map(*)) {
    ``[\documentclass[english,a4paper,`{string-join($config?apply-children($config, $node, $params?fontSize))}`]{`{string-join($config?apply-children($config, $node, $params?class))}`}
\usepackage[english]{babel}
\usepackage{colortbl}
\usepackage{xcolor}
\usepackage{fancyhdr}
\usepackage{listings}
\usepackage{graphicx}
\usepackage{mdframed}
\usepackage[export]{adjustbox}
\usepackage{hyperref}
\usepackage{longtable}
\usepackage{tabu}
\pagestyle{fancy}
\definecolor{myblue}{rgb}{0,0.1,0.6}
\definecolor{mygray}{rgb}{0.5,0.5,0.5}
\definecolor{mymauve}{rgb}{0.58,0,0.82}
\lstset{
basicstyle=\small\ttfamily,
columns=flexible,
keepspaces=true,
breaklines=true,
keywordstyle=\color{myblue}
}
\lstloadlanguages{xml}
\def\Gin@extensions{.pdf,.png,.jpg,.mps,.tif}
\graphicspath{{`{string-join($config?apply-children($config, $node, $params?image-dir))}`/doc/}}
`{string-join($config?apply-children($config, $node, $params?styles))}`
\begin{document}
`{string-join($config?apply-children($config, $node, $params?content))}`
\end{document}]``
};
(: generated template function for element spec: info :)
declare %private function model:template-info($config as map(*), $node as node()*, $params as map(*)) {
    ``[`{string-join($config?apply-children($config, $node, $params?content))}` \author{`{string-join($config?apply-children($config, $node, $params?author))}`}
\maketitle]``
};
(: generated template function for element spec: author :)
declare %private function model:template-author($config as map(*), $node as node()*, $params as map(*)) {
    ``[\and `{string-join($config?apply-children($config, $node, $params?content))}`]``
};
(: generated template function for element spec: author :)
declare %private function model:template-author2($config as map(*), $node as node()*, $params as map(*)) {
    ``[`{string-join($config?apply-children($config, $node, $params?content))}`]``
};
(: generated template function for element spec: title :)
declare %private function model:template-title($config as map(*), $node as node()*, $params as map(*)) {
    ``[\title{`{string-join($config?apply-children($config, $node, $params?content))}`}]``
};
(: generated template function for element spec: title :)
declare %private function model:template-title2($config as map(*), $node as node()*, $params as map(*)) {
    <t xmlns=""><h1><pb-link path="{$config?apply-children($config, $node, $params?path)}" emit="transcription">{$config?apply-children($config, $node, $params?content)}</pb-link></h1></t>/*
};
(: generated template function for element spec: code :)
declare %private function model:template-code($config as map(*), $node as node()*, $params as map(*)) {
    ``[\verb|`{string-join($config?apply-children($config, $node, $params?content))}`|]``
};
(: generated template function for element spec: note :)
declare %private function model:template-note2($config as map(*), $node as node()*, $params as map(*)) {
    ``[\begin{mdframed}[frametitle={`{string-join($config?apply-children($config, $node, $params?title))}`}]
`{string-join($config?apply-children($config, $node, $params?content))}`
\end{mdframed}]``
};
(: generated template function for element spec: videodata :)
declare %private function model:template-videodata($config as map(*), $node as node()*, $params as map(*)) {
    ``[\begin{center}
Not available in PDF edition. Go to \url{`{string-join($config?apply-children($config, $node, $params?content))}`} to view.
\end{center}]``
};
(:~

    Main entry point for the transformation.
    
 :)
declare function model:transform($options as map(*), $input as node()*) {
        
    let $config :=
        map:merge(($options,
            map {
                "output": ["latex","print"],
                "odd": "/db/apps/tei-publisher/odd/docbook.odd",
                "apply": model:apply#2,
                "apply-children": model:apply-children#3
            }
        ))
    let $config := latex:init($config, $input)
    
    return (
        
        let $output := model:apply($config, $input)
        return
            $output
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
                    case element(article) return
                        let $params := 
                            map {
                                "image-dir": $parameters?image-dir,
                                "styles": string-join($config("latex-styles"), '&#10;'),
                                "fontSize": ($config?font-size, "11pt")[1],
                                "class": ($config?class, "article")[1],
                                "content": .
                            }

                                                let $content := 
                            model:template-article($config, ., $params)
                        return
                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-article1"), $content)
                    case element(info) return
                        if (parent::article|parent::book) then
                            let $params := 
                                map {
                                    "content": title,
                                    "author": author
                                }

                                                        let $content := 
                                model:template-info($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-info1"), $content)
                        else
                            if (not(parent::article or parent::book)) then
                                latex:block($config, ., ("tei-info2"), .)
                            else
                                if ($parameters?header='short') then
                                    (
                                        latex:heading($config, ., ("tei-info4"), title, 5),
                                        if (author) then
                                            latex:block($config, ., ("tei-info5"), author)
                                        else
                                            ()
                                    )

                                else
                                    latex:block($config, ., ("tei-info6"), (title, author, pubdate, abstract))
                    case element(author) return
                        if (preceding-sibling::author) then
                            let $params := 
                                map {
                                    "content": (personname, affiliation)
                                }

                                                        let $content := 
                                model:template-author($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-author1"), $content)
                        else
                            if (preceding-sibling::author) then
                                latex:inline($config, ., ("tei-author3"), (', ', personname, affiliation))
                            else
                                (: More than one model without predicate found for ident author. Choosing first one. :)
                                let $params := 
                                    map {
                                        "content": (personname, affiliation)
                                    }

                                                                let $content := 
                                    model:template-author2($config, ., $params)
                                return
                                                                latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-author2"), $content)
                    case element(personname) return
                        latex:inline($config, ., ("tei-personname"), (firstname, ' ', surname))
                    case element(affiliation) return
                        latex:inline($config, ., ("tei-affiliation"), (', ', .))
                    case element(title) return
                        if (parent::info) then
                            let $params := 
                                map {
                                    "content": .
                                }

                                                        let $content := 
                                model:template-title($config, ., $params)
                            return
                                                        latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-title1"), $content)
                        else
                            if ($parameters?mode='summary') then
                                let $params := 
                                    map {
                                        "content": node(),
                                        "path": $parameters?path
                                    }

                                                                let $content := 
                                    model:template-title2($config, ., $params)
                                return
                                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-title2", "articletitle"), $content)
                            else
                                if ($parameters?mode='breadcrumbs') then
                                    latex:inline($config, ., ("tei-title3"), .)
                                else
                                    if (parent::note) then
                                        latex:inline($config, ., ("tei-title4"), .)
                                    else
                                        if (parent::info and $parameters?header='short') then
                                            latex:link($config, ., ("tei-title5"), ., $parameters?doc)
                                        else
                                            latex:heading($config, ., ("tei-title6", "title"), ., if ($parameters?view='single') then count(ancestor::section) + 1 else count($get(.)/ancestor::section))
                    case element(section) return
                        if ($parameters?mode='breadcrumbs') then
                            (
                                latex:inline($config, ., ("tei-section1"), $get(.)/ancestor::section/title),
                                latex:inline($config, ., ("tei-section2"), title)
                            )

                        else
                            latex:block($config, ., ("tei-section3"), .)
                    case element(para) return
                        latex:paragraph($config, ., ("tei-para"), .)
                    case element(emphasis) return
                        if (@role='bold') then
                            latex:inline($config, ., ("tei-emphasis1"), .)
                        else
                            latex:inline($config, ., ("tei-emphasis2"), .)
                    case element(code) return
                        let $params := 
                            map {
                                "content": .
                            }

                                                let $content := 
                            model:template-code($config, ., $params)
                        return
                                                latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-code1"), $content)
                    case element(figure) return
                        if (mediaobject/imageobject/imagedata[ends-with(@fileref, '.gif')]) then
                            latex:omit($config, ., ("tei-figure1"), .)
                        else
                            if (title|info/title) then
                                latex:figure($config, ., ("tei-figure2", "figure"), *[not(self::title|self::info)], title/node()|info/title/node())
                            else
                                latex:figure($config, ., ("tei-figure3"), ., ())
                    case element(informalfigure) return
                        if (caption) then
                            latex:figure($config, ., ("tei-informalfigure1", "figure"), *[not(self::caption)], caption/node())
                        else
                            latex:figure($config, ., ("tei-informalfigure2", "figure"), ., ())
                    case element(imagedata) return
                        latex:graphic($config, ., ("tei-imagedata1"), ., @fileref, (), (), (), ())
                    case element(itemizedlist) return
                        latex:list($config, ., ("tei-itemizedlist"), listitem, ())
                    case element(listitem) return
                        latex:listItem($config, ., ("tei-listitem"), ., ())
                    case element(orderedlist) return
                        latex:list($config, ., ("tei-orderedlist"), listitem, 'ordered')
                    case element(procedure) return
                        latex:list($config, ., ("tei-procedure"), step, 'ordered')
                    case element(step) return
                        latex:listItem($config, ., ("tei-step"), ., ())
                    case element(variablelist) return
                        model:definitionList($config, ., ("tei-variablelist"), varlistentry)
                    case element(varlistentry) return
                        model:definition($config, ., ("tei-varlistentry"), listitem/node(), term/node())
                    case element(table) return
                        if (title) then
                            (
                                latex:heading($config, ., ("tei-table1"), title, ()),
                                latex:table($config, ., ("tei-table2"), .//tr, map {"columns": max(.//tr ! count(td))})
                            )

                        else
                            latex:table($config, ., ("tei-table3", "table"), .//tr, map {"columns": max(.//tr ! count(td))})
                    case element(informaltable) return
                        latex:table($config, ., ("tei-informaltable", "table"), .//tr, map {"columns": max(.//tr ! count(td))})
                    case element(tr) return
                        latex:row($config, ., ("tei-tr"), .)
                    case element(td) return
                        if (parent::tr/parent::thead) then
                            latex:cell($config, ., ("tei-td1"), ., ())
                        else
                            latex:cell($config, ., ("tei-td2"), ., ())
                    case element(programlisting) return
                        model:code($config, ., ("tei-programlisting2"), .)
                    case element(synopsis) return
                        model:code($config, ., ("tei-synopsis2"), .)
                    case element(example) return
                        latex:figure($config, ., ("tei-example"), *[not(self::title|self::info)], info/title/node()|title/node())
                    case element(function) return
                        latex:inline($config, ., ("tei-function", "code"), .)
                    case element(command) return
                        latex:inline($config, ., ("tei-command", "code"), .)
                    case element(parameter) return
                        latex:inline($config, ., ("tei-parameter", "code"), .)
                    case element(filename) return
                        latex:inline($config, ., ("tei-filename", "code"), .)
                    case element(note) return
                        let $params := 
                            map {
                                "title": title,
                                "content": *[not(self::title)]
                            }

                                                let $content := 
                            model:template-note2($config, ., $params)
                        return
                                                latex:inline(map:merge(($config, map:entry("template", true()))), ., ("tei-note2"), $content)
                    case element(tag) return
                        latex:inline($config, ., ("tei-tag", "code"), .)
                    case element(link) return
                        if (@linkend) then
                            latex:link($config, ., ("tei-link3"), ., concat('?odd=', request:get-parameter('odd', ()), '&amp;view=',                             request:get-parameter('view', ()), '&amp;id=', @linkend))
                        else
                            latex:link($config, ., ("tei-link4"), ., @xlink:href)
                    case element(guibutton) return
                        latex:inline($config, ., ("tei-guibutton"), .)
                    case element(guilabel) return
                        latex:inline($config, ., ("tei-guilabel"), .)
                    case element(videodata) return
                        let $params := 
                            map {
                                "content": @fileref
                            }

                                                let $content := 
                            model:template-videodata($config, ., $params)
                        return
                                                latex:block(map:merge(($config, map:entry("template", true()))), ., ("tei-videodata1"), $content)
                    case element(mediaobject) return
                        if (imageobject/imagedata[ends-with(@fileref, '.gif')]) then
                            latex:omit($config, ., ("tei-mediaobject"), .)
                        else
                            $config?apply($config, ./node())
                    case element(abstract) return
                        if ($parameters?path = $parameters?active) then
                            latex:omit($config, ., ("tei-abstract1"), .)
                        else
                            latex:block($config, ., ("tei-abstract2"), .)
                    case element(pubdate) return
                        latex:inline($config, ., ("tei-pubdate", "pubdate"), format-date(., '[MNn] [D1], [Y0001]', 'en_US', (), ()))
                    case element(footnote) return
                        latex:note($config, ., ("tei-footnote"), ., (), ())
                    case element() return
                        latex:inline($config, ., ("tei--element"), .)
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

