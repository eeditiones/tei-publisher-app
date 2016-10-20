(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

declare variable $local:TeX_COMMAND := function($file) {
    ( "/usr/local/bin/pdflatex", "-interaction=nonstopmode", $file )
};

let $id := request:get-parameter("id", ())
let $token := request:get-parameter("token", ())
let $source := request:get-parameter("source", ())
return (
    response:set-cookie("simple.token", $token),
    if ($id) then
        let $id := replace($id, "^(.*)\..*", "$1")
        let $xml := pages:get-document($id)/tei:TEI
        let $tex := string-join($pm-config:latex-transform($xml, map { "image-dir": config:get-repo-dir() || "/" || $config:data-root || "/" }))
        let $file :=
            $id || format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]")
        return
            if ($source) then
                $tex
            else
                let $serialized := file:serialize-binary(util:string-to-binary($tex), $local:WORKING_DIR || "/" || $file || ".tex")
                let $options :=
                    <option>
                        <workingDir>{$local:WORKING_DIR}</workingDir>
                    </option>
                let $output :=
                    process:execute(
                        ( $local:TeX_COMMAND($file) ), $options
                    )
                return
                    if ($output/@exitCode < 2) then
                        let $pdf := file:read-binary($local:WORKING_DIR || "/" || $file || ".pdf")
                        return
                            response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                    else
                        $output
    else
        <p>No document specified</p>
)
