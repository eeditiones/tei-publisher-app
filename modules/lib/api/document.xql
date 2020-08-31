xquery version "3.1";

module namespace dapi="http://teipublisher.com/api/documents";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

declare function dapi:html($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    let $odd := head(($request?parameters?odd, $config:odd))
    return
        if ($doc) then
            let $xml := config:get-document($doc)/*
            let $config := tpu:parse-pi(root($xml), ())
            let $out := $pm-config:web-transform($xml, map { "root": $xml }, $config?odd)
            let $styles := if (count($out) > 1) then $out[1] else ()
            return
                dapi:postprocess(($out[2], $out[1])[1], $styles, $odd)
        else
            <p>No document specified</p>
};

declare %private function dapi:postprocess($nodes as node()*, $styles as element()?, $odd as xs:string) {
    let $oddName := replace($odd, "^.*/([^/\.]+)\.?.*$", "$1")
    for $node in $nodes
    return
        typeswitch($node)
            case element(head) return
                element { node-name($node) } {
                    $node/@*,
                    $node/node(),
                    <link rel="stylesheet" type="text/css" href="../transform/{replace($oddName, "^(.*)\.odd$", "$1")}-print.css" media="print"/>,
                    $styles
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    dapi:postprocess($node/node(), $styles, $odd)
                }
            default return
                $node
};

declare function dapi:latex($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $token := $request?parameters?token
    let $source := $request?parameters?source
    return (
        if ($token) then
            response:set-cookie("simple.token", $token)
        else
            (),
        if ($id) then
            let $log := util:log("INFO", "Loading doc: " || $id)
            let $xml := config:get-document($id)/*
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
                    let $serialized := file:serialize-binary(util:string-to-binary($tex), $config:tex-temp-dir || "/" || $file || ".tex")
                    let $options :=
                        <option>
                            <workingDir>{$config:tex-temp-dir}</workingDir>
                        </option>
                    let $output :=
                        for $i in 1 to 3
                        return
                            process:execute(
                                ( $config:tex-command($file) ), $options
                            )
                    return
                        if ($output[last()]/@exitCode < 2) then
                            let $pdf := file:read-binary($config:tex-temp-dir || "/" || $file || ".pdf")
                            return
                                response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                        else
                            $output
        else
            <p>No document specified</p>
    )
};