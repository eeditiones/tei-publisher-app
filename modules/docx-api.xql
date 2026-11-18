xquery version "3.1";

module namespace docx="http://teipublisher.com/api/docx";

import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare namespace pkg="http://schemas.microsoft.com/office/2006/xmlPackage";

declare variable $docx:MIME := "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

declare function docx:generate($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($id)
    return
        if (exists($doc)) then
            let $template := xmldb:decode($request?parameters?template)
            let $config := tpu:parse-pi(root($doc), (), $request?parameters?odd)
            let $odd := head(($request?parameters?odd, $config?odd))
            let $basename := replace($id, "^.*/([^/]+)$", "$1")
            let $filename := replace($basename, "\\.[^.]+$", "") || ".docx"
            let $params := map:merge((
                map:entry("root", $doc),
                if ($template) then
                    map:entry("docx-template", $config:app-root || "/" || $template)
                else
                    ()
            ))
            let $docxData := $pm-config:docx-transform($doc, $params, $odd)
            let $binary := docx:package-to-zip($docxData)
            return (
                if ($request?parameters?token) then
                    response:set-cookie("simple.token", $request?parameters?token)
                else
                    (),
                response:set-header("Content-Disposition", "attachment; filename=""" || $filename || """"),
                response:stream-binary($binary, $docx:MIME, $filename)
            )
        else
            error($errors:NOT_FOUND, "Document " || $id || " not found")
};

declare %private function docx:package-to-zip($docxData as item()*) as xs:base64Binary {
    let $package :=
        typeswitch($docxData)
            case element(pkg:package) return $docxData
            case document-node() return $docxData/*[self::pkg:package]
            default return ()
    return
        if (empty($package)) then
            error($errors:BAD_REQUEST, "DOCX transform did not return a pkg:package")
        else
            docx:zip-package($package)
};

declare %private function docx:zip-package($package as element(pkg:package)) as xs:base64Binary {
    let $entries :=
        for $part in $package/pkg:part
        let $name := replace($part/@pkg:name/string(), "^/", "")
        let $method := if ($part/@pkg:compression/string() = "store") then "store" else ()
        return
            if ($part/pkg:xmlData) then
                element entry {
                    attribute name { $name },
                    attribute type { "xml" },
                    if ($method) then attribute method { $method } else (),
                    $part/pkg:xmlData/node()
                }
            else if ($part/pkg:binaryData) then
                element entry {
                    attribute name { $name },
                    attribute type { "binary" },
                    if ($method) then attribute method { $method } else (),
                    xs:base64Binary(normalize-space($part/pkg:binaryData/string()))
                }
            else
                ()
    return
        compression:zip($entries, true())
};
