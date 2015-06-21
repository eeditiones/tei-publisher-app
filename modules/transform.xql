(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 : 
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "../content/odd2odd.xql";

declare option output:method "html";
declare option output:html-version "5.0";
declare option output:media-type "text/html";

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", $config:default-odd)
return
    if ($doc) then
        let $odd := odd:get-compiled($config:odd-root, $odd, $config:compiled-odd-root)
        let $xml := doc($config:app-root || "/" || $doc)
        return
            pmu:process($odd, $xml, $config:output-root, "web", "../generated", $config:module-config)
    else
        <p>No document specified</p>