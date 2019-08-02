(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";

declare option output:method "html";
declare option output:html-version "5.0";
declare option output:media-type "text/html";

declare function local:postprocess($nodes as node()*, $styles as element()?, $odd as xs:string) {
    let $oddName := replace($odd, "^.*/([^/\.]+)\.?.*$", "$1")
    for $node in $nodes
    return
        typeswitch($node)
            case element(head) return
                element { node-name($node) } {
                    $node/@*,
                    $node/node(),
                    <link rel="stylesheet" type="text/css" href="../transform/{replace($oddName, "^(.*)\.odd$", "$1")}-print.css" media="print"/>,
                    $styles
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    local:postprocess($node/node(), $styles, $odd)
                }
            default return
                $node
};

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", $config:odd)
return
    if ($doc) then
        let $xml := pages:get-document($doc)/*
        let $config := tpu:parse-pi(root($xml), ())
        let $out := $pm-config:web-transform($xml, map { "root": $xml }, $config?odd)
        let $styles := if (count($out) > 1) then $out[1] else ()
        return
            local:postprocess(($out[2], $out[1])[1], $styles, $odd)
    else
        <p>No document specified</p>
