(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 : 
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "../content/odd2odd.xql";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:html-version "5.0";
declare option output:media-type "text/xml";

declare variable $local:CONFIG := 
    <fop version="1.0">
        <!-- Strict user configuration -->
        <strict-configuration>true</strict-configuration>
        
        <!-- Strict FO validation -->
        <strict-validation>false</strict-validation>
        
        <!-- Base URL for resolving relative URLs -->
        <base>./</base>
        
        <!-- Font Base URL for resolving relative font URLs -->
        <font-base>{substring-before(request:get-url(), "/modules")}/resources/fonts/</font-base>
        <renderers>
            <renderer mime="application/pdf">
                <fonts>
                    <font kerning="yes"
                        embed-url="Junicode.ttf"
                        encoding-mode="single-byte">
                        <font-triplet name="Junicode" style="normal" weight="normal"/>
                    </font>
                    <font kerning="yes"
                        embed-url="Junicode-Bold.ttf"
                        encoding-mode="single-byte">
                        <font-triplet name="Junicode" style="normal" weight="700"/>
                    </font>
                    <font kerning="yes"
                        embed-url="Junicode-Italic.ttf"
                        encoding-mode="single-byte">
                        <font-triplet name="Junicode" style="italic" weight="normal"/>
                    </font>
                    <font kerning="yes"
                        embed-url="Junicode-BoldItalic.ttf"
                        encoding-mode="single-byte">
                        <font-triplet name="Junicode" style="italic" weight="700"/>
                    </font>
                </fonts>
            </renderer>
        </renderers>
    </fop>;

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", $config:default-odd)
let $source := request:get-parameter("source", ())
return
    if ($doc) then
        let $xml := doc($config:app-root || "/" || $doc)
        let $fo :=
                pmu:process(odd:get-compiled($config:odd-root, $odd, $config:compiled-odd-root), $xml, $config:output-root, "print", "../" || $config:output, $config:module-config)
        return
            if ($source) then
                $fo
            else
                let $pdf := xslfo:render($fo, "application/pdf", (), $local:CONFIG)
                return
                    response:stream-binary($pdf, "media-type=application/pdf", replace($doc, "^.*?([^/]+)\..*", "$1") || ".pdf")
    else
        <p>No document specified</p>