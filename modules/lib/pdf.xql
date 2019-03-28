xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace xslfo="http://exist-db.org/xquery/xslfo" at "java:org.exist.xquery.modules.xslfo.XSLFOModule";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace fo="http://www.w3.org/1999/XSL/Format";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:omit-xml-declaration "no";

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

declare function local:fop($id as xs:string, $fontsDir as xs:string?, $fo as element()) {
    xslfo:render($fo, "application/pdf", (), $config:fop-config)
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

declare function local:get-cached($id as xs:string, $doc as element()) {
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
let $id := replace($path, "^(.*)\..*", "$1")
let $doc := root(pages:get-document($id))
let $config := tpu:parse-pi(root($doc), ())
let $name := util:document-name($doc)
return
    if ($doc) then
        let $cached := if ($useCache = ("yes", "true")) then local:get-cached($name, $doc) else ()
        return (
            response:set-cookie("simple.token", $token),
            if (not($source) and exists($cached)) then (
                response:stream-binary($cached, "media-type=application/pdf", $id || ".pdf")
            ) else
                let $start := util:system-time()
                let $fo := $pm-config:print-transform($doc, map { "root": $doc }, $config?odd)
                return (
                    if ($source) then
                        $fo
                    else
                        let $output :=
                            switch ($local:PROCESSOR)
                                case "ah" return
                                    local:antenna-house($name, $fo)
                                default return
                                    local:fop($name, config:get-fonts-dir(), $fo)
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
