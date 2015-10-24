xquery version "3.0";


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:omit-xml-declaration "no";

import module namespace config="$$config-namespace$$" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "/db/apps/tei-simple/content/util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "/db/apps/tei-simple/content/odd2odd.xql";
import module namespace xslfo="http://exist-db.org/xquery/xslfo" at "java:org.exist.xquery.modules.xslfo.XSLFOModule";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";
(:  Set to 'ah' for AntennaHouse, 'fop' for Apache fop :)
declare variable $local:PROCESSOR := "fop";

declare variable $local:CACHE := true();

declare variable $local:CACHE_COLLECTION := $config:app-root || "/cache";

declare function local:prepare-cache-collection() {
    if (xmldb:collection-available($local:CACHE_COLLECTION)) then
        ()
    else
        (xmldb:create-collection($config:app-root, "cache"))[2]
};

declare function local:fop($id as xs:string, $fo as element()) {
    let $appName := config:expath-descriptor()/@abbrev
    let $config :=
    <fop version="1.0">
        <!-- Strict user configuration -->
        <strict-configuration>true</strict-configuration>
    
        <!-- Strict FO validation -->
        <strict-validation>no</strict-validation>
    
        <!-- Font Base URL for resolving relative font URLs -->
        <font-base>{substring-before(request:get-url(), "/" || $appName)}/tei-simple/resources/fonts/</font-base>
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
    </fop>
let $log := console:log("Calling fop ...")
let $pdf := xslfo:render($fo, "application/pdf", (), $config)
return
    $pdf
};

declare function local:antenna-house($id as xs:string, $fo as element()) {
    let $file := 
        $local:WORKING_DIR || "/" || encode-for-uri($id) || 
        format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]") || "-" || request:get-remote-addr()
    let $serialized := file:serialize($fo, $file || ".fo", "indent=no")
    let $options :=
        <option>
            <workingDir>{system:get-exist-home()}</workingDir>
        </option>
    let $result := (
        console:log("Calling AntennaHouse ..."),
        process:execute(
            (
                "sh", "/usr/AHFormatterV6_64/run.sh", "-d", $file || ".fo", "-o", $file || ".pdf", "-x", "2",
                "-peb", "1", "-pdfver", "PDF1.6", 
                "-p", "@PDF",
                "-tpdf"
            ), $options
        )
    )
    return (
        console:log("sarit", $result),
        if ($result/@exitCode = 0) then
            let $pdf := file:read-binary($file || ".pdf")
            return
                $pdf
        else
            $result
    )
};

declare function local:cache($id as xs:string, $output as xs:base64Binary) {
    local:prepare-cache-collection(),
    xmldb:store($local:CACHE_COLLECTION, $id || ".pdf", $output, "application/pdf")
};

declare function local:get-cached($id as xs:string, $doc as element(tei:TEI)) {
    let $path := $local:CACHE_COLLECTION || "/" ||  $id || ".pdf"
    return
        if ($local:CACHE and util:binary-doc-available($path)) then
            let $modDatePDF := xmldb:last-modified($local:CACHE_COLLECTION, $id || ".pdf")
            let $modDateSrc := xmldb:last-modified(util:collection-name($doc), util:document-name($doc))
            return
                if ($modDatePDF >= $modDateSrc) then
                    util:binary-doc($path)
                else
                    ()
        else
            ()
};

let $path := request:get-parameter("doc", ())
let $token := request:get-parameter("token", "none")
let $source := request:get-parameter("source", ())
let $useCache := request:get-parameter("cache", "yes")
let $doc := doc($config:data-root || "/" || $path)/tei:TEI
let $id := replace($path, "^(.*)\..*", "$1")
let $log := console:log("Generating PDF for " || $config:data-root || "/" || $path)
let $name := util:document-name($doc)
return
    if ($doc) then
        let $cached := if ($useCache = ("yes", "true")) then local:get-cached($name, $doc) else ()
        return (
            response:set-cookie("sarit.token", $token),
            if (not($source) and exists($cached)) then (
                console:log("Reading " || $name || " pdf from cache"),
                response:stream-binary($cached, "media-type=application/pdf", $id || ".pdf")
            ) else
                let $start := util:system-time()
                let $fo := pmu:process(odd:get-compiled($config:odd-root, $config:odd, $config:compiled-odd-root), $doc, $config:output-root, "print", "../" || $config:output, $config:module-config)
                return (
                    console:log("Generated fo for " || $name || " in " || util:system-time() - $start),
                    if ($source) then
                        $fo
                    else
                        let $output :=
                            switch ($local:PROCESSOR)
                                case "ah" return
                                    local:antenna-house($name, $fo)
                                default return
                                    local:fop($name, $fo)
                        return
                            typeswitch($output)
                                case xs:base64Binary return (
                                    let $path := local:cache($name, $output)
                                    return
                                        response:stream-binary(util:binary-doc($path), "media-type=application/pdf", $id || ".pdf")
                                )
                                default return
                                    $output
                )
        )
    else
        ()