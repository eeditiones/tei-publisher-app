xquery version "3.1";

(:~
 : Extension functions for epub generation.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/epub";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:break($config as map(*), $node as element(), $class as xs:string+, $content, $type as xs:string, $label as xs:string*) {
    switch($type)
        case "page" return
            if ($label) then
                <span class="{$class}" 
                    title="{$config?apply-children($config, $node, $content)}">[p. <span>{$config?apply-children($config, $node, $label)}</span>]</span>
            else
                <span class="{$class}">[{$config?apply-children($config, $node, $content)}]</span>
        default return
            <br/>
};

declare function pmf:cells($config as map(*), $node as element(), $class as xs:string+, $content) {
    <tr>
    {
        for $cell in $content/node() | $content/@*
        return
            <td class="{$class}">{$config?apply-children($config, $node, $cell)}</td>
    }
    </tr>
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content, $place as xs:string?, $label as xs:string?) {
    let $id := translate(generate-id($node), ".", "_")
    return
        switch ($place)
            case "margin" return (
                <a id="A{$id}" class="note {$class}" href="endnotes.html#{$id}">
                {count($node/preceding::tei:note intersect $node/ancestor::tei:body//tei:note) + 1}
                </a>,
                <span id="{$id}" class="endnote" style="display: none;">
                { $config?apply($config, $content/node()) }
                </span>
            )
            default return (
                <a id="A{$id}" class="note {$class}" href="endnotes.html#{$id}">
                {count($node/preceding::tei:note intersect $node/ancestor::tei:body//tei:note) + 1}
                </a>,
                <span id="{$id}" class="endnote" style="display: none;">
                { $config?apply($config, $content/node()) }
                </span>
            )
};