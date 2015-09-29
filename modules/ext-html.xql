xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:code($config as map(*), $node as element(), $class as xs:string, $content as node()*, $lang as item()?) {
    <pre class="sourcecode" data-language="{if ($lang) then $lang else 'xquery'}">
    {replace(string-join($content/node()), "^\s+?(.*)\s+$", "$1")}
    </pre>
};