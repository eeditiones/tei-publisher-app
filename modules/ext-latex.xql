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