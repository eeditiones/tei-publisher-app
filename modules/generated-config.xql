xquery version "3.1";

(:~
 : Generated configuration – do not edit
 :)
module namespace config="https://e-editiones.org/tei-publisher/generator/config";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $config:webcomponents := "3.0.4";
declare variable $config:webcomponents-cdn := "https://cdn.jsdelivr.net/npm/@teipublisher/pb-components";
declare variable $config:fore := "";

declare variable $config:default-view := "div";
declare variable $config:default-template := "basic.html";
declare variable $config:default-media := ("web", "print", "epub", "markdown");
declare variable $config:search-default := "";
declare variable $config:sort-default := "category";


    
    declare variable $config:data-root := $config:app-root || "/data";
    



    declare variable $config:data-default := $config:data-root;



    
    declare variable $config:register-root := $config:data-root || "/registers";
    


declare variable $config:data-exclude := (
    doc($config:data-root || '/taxonomy.xml')//tei:text,
 collection($config:register-root)//tei:text
);

declare variable $config:odd-root := $config:app-root || "/resources/odd";
declare variable $config:default-odd := "teipublisher.odd";
declare variable $config:odd-internal := 
    ( "docx.odd" );

declare variable $config:odd-available :=
xmldb:get-child-resources($config:odd-root)[ends-with(., '.odd')][not(. = ('teipublisher_odds.odd', 'teilite.odd'))];

declare variable $config:odd-media := ("web", "print", "epub", "markdown");

(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:pagination-depth := 10;

declare variable $config:pagination-fill := 5;

declare variable $config:address-by-id as xs:boolean :=  false() ;

declare variable $config:default-language as xs:string := "";

declare variable $config:context-path :=
    
    let $prop := util:system-property("teipublisher.context-path")
    return
        if (exists($prop)) then
            if ($prop = "auto") then
                request:get-context-path() || substring-after($config:app-root, "/db") 
            else
                $prop
        else if (exists(request:get-header("X-Forwarded-Host")))
            then ""
        else
            request:get-context-path() || substring-after($config:app-root, "/db")
    
;

(:~
 : Use the JSON configuration to determine which configuration applies for which collection
 :)
declare function config:collection-config($collection as xs:string?, $docUri as xs:string?) {
    
    switch ($collection)
        
        case "demo" return
            map{"template":"basic.html"}
         
        case "jats" return
            map{"odd":"jats.odd","template":"jats.html"}
         
        case "doc" return
            map{"odd":"docbook.odd","media":["web","print","fo","epub","markdown"],"template":"documentation.html"}
         
        case "docx" return
            map{"odd":"docx-output.odd","template":"docx.html"}
        
        default return
            ()
    
};