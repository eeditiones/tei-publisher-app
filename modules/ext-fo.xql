xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-fo";

import module namespace print="http://www.tei-c.org/tei-simple/xquery/functions/fo" at "../content/fo-functions.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace fo="http://www.w3.org/1999/XSL/Format";

declare function pmf:code($config as map(*), $node as element(), $class as xs:string+, $content as node()*, $lang as item()?) {
    <fo:block>
    {
        print:check-styles($config, $node, $class, ()),
        $config?apply-children($config, $node, $content)
    }
    </fo:block>
};