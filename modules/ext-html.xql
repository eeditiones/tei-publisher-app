xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

declare function pmf:code($config as map(*), $node as element(), $class as xs:string+, $content as node()*, $lang as item()?) {
    <pre class="code" data-language="{if ($lang) then $lang else 'xquery'}">
    {replace(string-join($content/node()), "^\s+?(.*)\s+$", "$1")}
    </pre>
};

declare function pmf:panel($config as map(*), $node as element(), $class as xs:string+, $content as item()*, $title as item()?) {
    <div class="panel {$class}">
        <div class="panel-heading">{ html:apply-children($config, $node, $title) }</div>
        <div class="panel-body">{ html:apply-children($config, $node, $content) }</div>
    </div>
};

declare function pmf:definitionList($config as map(*), $node as element(), $class as xs:string+, $content as node()*) {
    <dl>{ html:apply-children($config, $node, $content) }</dl>
};

declare function pmf:definitionTerm($config as map(*), $node as element(), $class as xs:string+, $content as node()*) {
    <dt>{ html:apply-children($config, $node, $content) }</dt>
};

declare function pmf:definitionDef($config as map(*), $node as element(), $class as xs:string+, $content as node()*) {
    <dd>{ html:apply-children($config, $node, $content) }</dd>
};
