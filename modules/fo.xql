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
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:html-version "5.0";
declare option output:media-type "text/xml";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", "teisimple.odd")
return
    if ($doc) then
        let $xml := doc($config:data-root || "/" || $doc)
        let $fo :=
                pmu:process($config:odd-root || "/" || $odd, $xml, $config:output-root, "fo", "../generated")
        let $pdf := xslfo:render($fo, "application/pdf", ())
        return
            response:stream-binary($pdf, "media-type=application/pdf", replace($doc, "^(.*?)\..*", "$1") || ".pdf")
    else
        <p>No document specified</p>