(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

declare variable $local:OUTPUT_DIR := $local:WORKING_DIR || "/teisimple-temp";

declare variable $local:TeX_COMMAND := function($file) {
    ( "/usr/local/texlive/2015/bin/x86_64-darwin/xelatex", "-interaction=nonstopmode", $file )
};

declare function local:create-output-dir() {
    if (file:is-directory($local:OUTPUT_DIR)) then
        if (file:is-writeable($local:OUTPUT_DIR)) then
            $local:OUTPUT_DIR
        else
            error(xs:QName("local:err-output"), "Temp directory " || $local:OUTPUT_DIR || " is not writable")
    else
        let $created := file:mkdir($local:OUTPUT_DIR)
        return
            if ($created) then
                $local:OUTPUT_DIR
            else
                error(xs:QName("local:err-output"), "Failed to create temp directory " || $local:OUTPUT_DIR)
};

let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", $config:default-odd)
let $source := request:get-parameter("source", ())
let $dir := local:create-output-dir()
return
    if ($doc) then
        let $xml := doc($config:app-root || "/" || $doc)
        let $tex :=
            string-join(
                pmu:process(
                    odd:get-compiled($config:odd-root, $odd, $config:compiled-odd-root),
                    $xml, $config:output-root, "latex", "../" || $config:output,
                    $config:module-config,
                    map { "image-dir": config:get-repo-dir() || "/" || replace($doc, "^(.*?)/[^/]*$", "$1") || "/" }
                )
            )
        let $file :=
            replace($doc, "^.*?([^/]+)\..*$", "$1-") ||
            substring(util:uuid(), 1, 8) ||
            format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00][s00]")
        return
            if ($source) then
                $tex
            else
                let $serialized := file:serialize-binary(util:string-to-binary($tex), $dir || "/" || $file || ".tex")
                let $options :=
                    <option>
                        <workingDir>{$dir}</workingDir>
                    </option>
                let $output :=
                    process:execute(
                        ( $local:TeX_COMMAND($file) ), $options
                    )
                let $output :=
                    if ($output/@existCode < 2) then
                        process:execute(
                            ( $local:TeX_COMMAND($file) ), $options
                        )
                    else
                        $output
                let $log := console:log($output)
                return
                    if ($output/@exitCode < 2) then
                        let $pdf := file:read-binary($dir || "/" || $file || ".pdf")
                        return
                            response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                    else
                        $output
    else
        <p>No document specified</p>
