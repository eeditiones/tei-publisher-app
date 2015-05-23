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
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "odd2odd.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

declare variable $local:TeX_COMMAND := function($file) {
    ( "/opt/local/bin/pdflatex", "-interaction=nonstopmode", $file )
};

declare variable $local:ext-latex := 
    map {
        "uri": "http://www.tei-c.org/tei-simple/xquery/ext-latex",
        "prefix": "ext",
        "at": "../modules/ext-latex.xql"
    };
    
let $doc := request:get-parameter("doc", ())
let $odd := request:get-parameter("odd", "teisimple.odd")
let $source := request:get-parameter("source", ())
return
    if ($doc) then
        let $xml := doc($config:app-root || "/" || $doc)
        let $tex :=
            string-join(
                pmu:process(odd:get-compiled($odd), $xml, $config:output-root, "latex", "../generated", $local:ext-latex)
            )
        let $file := 
            replace($doc, "^.*?([^/]+)\..*$", "$1") ||
            "-" || request:get-remote-addr() ||
            format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]")
        return
            if ($source) then
                $tex
            else
                let $dir := $local:WORKING_DIR || "/" || $file
                let $mkdir := file:mkdir($local:WORKING_DIR || "/" || $file)
                return
                    if ($mkdir) then
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
                    else (
                        response:set-status-code(404),
                        <p>Failed to create output directory: {$dir}</p>
                    )
    else
        <p>No document specified</p>