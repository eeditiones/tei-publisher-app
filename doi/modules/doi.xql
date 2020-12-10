xquery version "3.1";

module namespace doi="http://teipublisher.com/api/doi";

import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace docx="http://existsolutions.com/teipublisher/docx";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace register = "http://existsolutions.com/app/doi/registration" at "../../../doi/modules/register-doi.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
(:
    file upload with DOI registration.

    Upload will not stop when DOI registration fails but log an error and return appropriate
    error message to the client. However it must be noted that this requires that a consumer
    analyzes 200 responses for potential errors.

    @server the absolute http URL of the server including port
    @root the root collection of this app
    @paths the filenames of the uploaded files
    @payloads the binary uploaded files
    @availability used during registration of DOI

:)

declare function doi:upload($request as map(*)) {
    let $name := request:get-uploaded-file-name("files[]")
    let $data := request:get-uploaded-file-data("files[]")
    let $availability := $request?parameters?availability
    let $server-root := $request?config?spec?servers(1)?url
    let $length := $request?parameters?content-Length
    return
        array { doi:uploadCollection($server-root,$request?parameters?collection, $name, $data, $length,$availability) }
};

(:
    file upload with DOI registration to a given target collection.

    Upload will not stop when DOI registration fails but log an error and return appropriate
    error message to the client. However it must be noted that this requires that a consumer
    analyzes 200 responses for potential errors.

    @server the absolute http URL of the server including port
    @root the root collection of this app
    @paths the filenames of the uploaded files
    @payloads the binary uploaded files
    @availability used during registration of DOI

:)
declare %private function doi:uploadCollection($server, $root, $paths, $payloads, $length, $availability) {
    for-each-pair($paths, $payloads, function($path, $data) {

        let $origPath := $path
        let $path := doi:storeFile($root, $path,$data)

        (: ### DOI registration part ### :)
        let $url := $server || $config:data-dir || "/" || $origPath
        let $stored := doc($path)
        return
            try {        
                let $doi := register:register-doi-for-document($stored, $url, $availability)
                let $idno := <idno xmlns="http://www.tei-c.org/ns/1.0" type="DOI">{$doi?doi}</idno>
                let $updated := 
                
                (
                    update delete $stored//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="DOI"],
                    update insert $idno into $stored//tei:teiHeader/tei:fileDesc/tei:publicationStmt
                )
                
                return
                    map {
                        "name": $path,
                        "path": substring-after($path, $config:data-root || "/" || $root),
                        "type": xmldb:get-mime-type($path),
                        "size": $length,
                        "doi": $doi?doi,
                        "doi-detail":"DOI created"
                    }
            } catch * {
                let $log := util:log('error', 'DOI Registration failed ' || $err:description)
                return
                map {
                    "name": $path,
                    "path": substring-after($path, $config:data-root || "/" || $root),
                    "type": xmldb:get-mime-type($path),
                    "size": $length,
                    "doi": "DOI registration failed",
                    "doi-detail": $err:description 
                }
            }
    })
};

declare %private function doi:storeFile($root, $path, $data){
    if (ends-with($path, ".odd")) then
        xmldb:store($config:odd-root, xmldb:encode($path), $data)
    else
        let $collectionPath := $config:data-root || "/" || $root
        return
            if (xmldb:collection-available($collectionPath)) then
                if (ends-with($path, ".docx")) then
                    let $mediaPath := $config:data-root || "/" || $root || "/" || xmldb:encode($path) || ".media"
                    let $stored := xmldb:store($collectionPath, xmldb:encode($path), $data)
                    let $tei :=
                        docx:process($stored, $config:data-root, $pm-config:tei-transform(?, ?, "docx.odd"), $mediaPath)
                    let $teiDoc :=
                        document {
                            processing-instruction teipublisher {
                                $config:default-docx-pi
                            },
                            $tei
                        }
                    return
                        xmldb:store($collectionPath, xmldb:encode($path) || ".xml", $teiDoc)
                else
                    xmldb:store($collectionPath, xmldb:encode($path), $data)
                else
                    error($errors:NOT_FOUND, "Collection not found: " || $collectionPath)
};

