(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:html-version "5.0";
declare option output:media-type "text/xml";

declare function local:config($fontsDir as xs:string?) {
    <fop version="1.0">
        <!-- Strict user configuration -->
        <strict-configuration>true</strict-configuration>

        <!-- Strict FO validation -->
        <strict-validation>false</strict-validation>

        <!-- Base URL for resolving relative URLs -->
        <base>./</base>

        <renderers>
            <renderer mime="application/pdf">
                <fonts>
                {
                    if ($fontsDir) then (
                        <font kerning="yes"
                            embed-url="file:{$fontsDir}/Junicode.ttf"
                            encoding-mode="single-byte">
                            <font-triplet name="Junicode" style="normal" weight="normal"/>
                        </font>,
                        <font kerning="yes"
                            embed-url="file:{$fontsDir}/Junicode-Bold.ttf"
                            encoding-mode="single-byte">
                            <font-triplet name="Junicode" style="normal" weight="700"/>
                        </font>,
                        <font kerning="yes"
                            embed-url="file:{$fontsDir}/Junicode-Italic.ttf"
                            encoding-mode="single-byte">
                            <font-triplet name="Junicode" style="italic" weight="normal"/>
                        </font>,
                        <font kerning="yes"
                            embed-url="file:{$fontsDir}/Junicode-BoldItalic.ttf"
                            encoding-mode="single-byte">
                            <font-triplet name="Junicode" style="italic" weight="700"/>
                        </font>
                    ) else
                        ()
                }
                </fonts>
            </renderer>
        </renderers>
    </fop>
};


let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", $config:default-odd)
let $token := request:get-parameter("token", "none")
let $source := request:get-parameter("source", ())
let $fontsDir := config:get-fonts-dir()
return
    if ($doc) then (
        response:set-cookie("simple.token", $token),
        let $xml := doc($config:app-root || "/" || $doc)
        let $fo :=
                pmu:process(odd:get-compiled($config:odd-root, $odd), $xml, $config:output-root, "print", "../" || $config:output, $config:module-config)
        return
            if ($source) then
                $fo
            else
                let $pdf := xslfo:render($fo, "application/pdf", (), local:config($fontsDir))
                return
                    response:stream-binary($pdf, "media-type=application/pdf", replace($doc, "^.*?([^/]+)\..*", "$1") || ".pdf")
    ) else
        <p>No document specified</p>
