xquery version "3.1";

module namespace dara = "http://existsolutions.com/app/dara";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";

import module namespace http = "http://expath.org/ns/http-client";


(:  
    Testsystem:
        {$dara:registrar}/mydara?lang=en 
        Username: dipf2
        Passwort: labs_dipf#2019
    DOI Registration: 
        https://www.da-ra.de/en/technical-information/doi-registration/#c1203
    API
        https://labs.da-ra.de/apireference/#/DOI/getResourceIdentifier 
  :)

declare variable $dara:config := doc("../config.xml");
declare variable $dara:registrar := $dara:config//registrar/text();
declare variable $dara:getUrl := $dara:config//get/text();
declare variable $dara:postUrl := $dara:config//post/text();


declare variable $dara:secret := doc("/db/system/security/doi-secret.xml");
declare variable $dara:username := $dara:secret/secret/user/text();
declare variable $dara:password := $dara:secret/secret/password/text();


declare function dara:get-resource-identifier($dara) {
    let $request := 
        <http:request 
            href="{$dara:registrar}{$dara:getUrl}?doi={encode-for-uri($dara)}"
            method="get"
            username="{ $dara:username }"
            password="{ $dara:password }"
            auth-method="basic"
            send-authorization="true">
            <http:header name="accept" value="application/json"/>
        </http:request>
    
    let $response := http:send-request($request)
    return
        if($response[1]/@status = 200 or $response[1]/@status = 201)
        then (
            let $json := util:binary-to-string($response[2])
            return
                json-to-xml($json)     
        )  else (
            <error status="{$response[1]/@status}">
                {
                    $response[1],
                    if(exists($response[2]))
                    then (
                        let $json := util:binary-to-string($response[2])
                        return
                            json-to-xml($json)     
                    )
                    else () 
                }
            </error>
        )
};


(:
  register (create) or update a DOI by using registrar service (DARA API)
  
  @param $resource the DOI metadata for the resource to be registered
  @param $registration boolean value - if true() a new DOI will be created for the resource
:)
declare function dara:create-update-resource($resource, $registration) {

    let $request := 
        <http:request method="post" username="{$dara:username}" password="{$dara:password}" auth-method="basic"
                send-authorization="true">
                    <http:body media-type='application/xml'/>
                    <http:header name="accept" value="application/json"/>
        </http:request>
    let $href := $dara:registrar || $dara:postUrl || '?registration=' || $registration
    let $response := http:send-request($request,
                                        $href,
                                        $resource)
    
    let $log := util:log('info',util:binary-to-string($response[2]))
    
    let $status := $response[1]/@status
    let $json := parse-json(util:binary-to-string($response[2]))
    return
        if($status = 200 or $status = 201)
        then $json
        else if($status = 400) then
            error($errors:BAD_REQUEST, $json?errors?detail)
        else if($status = 401) then
            error($errors:UNAUTHORIZED,$json?message)
        else if($status = 403) then
            error($errors:FORBIDDEN, $json?errors?detail)
        else
            error(xs:QName("errors:SERVER_ERROR_500"),"internal Server Error at dara Registrar")
};
