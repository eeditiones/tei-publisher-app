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
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

let $id := request:get-parameter("id", ())
let $token := request:get-parameter("token", ())
let $source := request:get-parameter("source", ())
return (
    if ($token) then
        response:set-cookie("simple.token", $token)
    else
        (),
    if ($id) then
        let $id := replace($id, "^(.*)\..*", "$1")
        let $xml := pages:get-document($id)/*
        let $config := tpu:parse-pi(root($xml), ())
        let $options :=
            map {
                "root": $xml,
                "image-dir": config:get-repo-dir() || "/" ||
                    substring-after($config:data-root[1], $config:app-root) || "/"
            }
        let $tex := string-join($pm-config:latex-transform($xml, $options, $config?odd))
        let $file :=
            replace($id, "^.*?([^/]+)$", "$1") || format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]")
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
                    for $i in 1 to 3
                    return
                        process:execute(
                            ( $config:tex-command($file) ), $options
                        )
                return
                    if ($output[last()]/@exitCode < 2) then
                        let $pdf := file:read-binary($local:WORKING_DIR || "/" || $file || ".pdf")
                        return
                            response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                    else
                        $output
    else
        <p>No document specified</p>
)
