xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/ext-html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";

declare function pmf:iframe($config as map(*), $node as element(), $class as xs:string+, $content as item()*, $src, $width, $height) {
    <iframe src="{$src}" frameborder="0" gesture="media" allow="encrypted-media" allowfullscreen="allowfullscreen">
    {
        if ($width) then
            attribute width { $width }
        else
            (),
        if ($height) then
            attribute height { $height }
        else
            ()
    }
    </iframe>
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
