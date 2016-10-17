xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://www.tei-c.org/tei-simple/config";

import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";

(:
 : The default to use for determining the amount of content to be shown
 : on a single page. Possible values: 'div' for showing entire divs (see
 : the parameters below for further configuration), or 'page' to browse
 : a document by actual pages determined by TEI pb elements. 
 :)
declare variable $config:default-view := "$$default-view$$";

(:
 : The element to search by default, either 'tei:div' or 'tei:body'.
 :)
declare variable $config:search-default := "$$default-search$$";

(: 
 : Defines which nested divs will be displayed as single units on one
 : page (using pagination by div). Divs which are nested
 : deeper than $pagination-depth will always appear in their parent div.
 : So if you have, for example, 4 levels of divs, but the divs on level 4 are
 : just small sub-subsections with one paragraph each, you may want to limit
 : $pagination-depth to 3 to not show the sub-subsections as separate pages.
 : Setting $pagination-depth to 1 would show entire top-level divs on one page.
 :)
declare variable $config:pagination-depth := 10;

(:
 : If a div starts with less than $pagination-fill elements before the
 : first nested div child, the pagination-by-div algorithm tries to fill
 : up the page by pulling following divs in. When set to 0, it will never
 : attempt to fill up the page.
 :)
declare variable $config:pagination-fill := 5;

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

declare variable $config:data-root := $$config-data$$;

declare variable $config:odd := "$$config-odd$$";

declare variable $config:odd-root := $config:app-root || "/resources/odd";
declare variable $config:compiled-odd-root := $config:odd-root || "/compiled";

declare variable $config:output := "transform";

declare variable $config:output-root := $config:app-root || "/" || $config:output;

declare variable $config:module-config := doc($config:odd-root || "/configuration.xml")/*;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare function config:get-relpath($node as node()) {
    substring-after(document-uri(root($node)), $config:data-root || "/")
};

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};

(: Try to dynamically determine data directory by calling JMX. :)
declare function config:get-data-dir() as xs:string? {
    try {
        let $request := <http:request method="GET" href="http://localhost:{request:get-server-port()}/{request:get-context-path()}/status?c=disk"/>
        let $response := http:send-request($request)
        return
            if ($response[1]/@status = "200") then
                $response[2]//jmx:DataDirectory/string()
            else
                ()
    } catch * {
        ()
    }
};

declare function config:get-repo-dir() {
    let $dataDir := config:get-data-dir()
    let $pkgRoot := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version
    return
        if ($dataDir) then
            $dataDir || "/expathrepo/" || $pkgRoot
        else
            ()
};


declare function config:get-fonts-dir() as xs:string? {
    let $repoDir := config:get-repo-dir()
    return
        if ($repoDir) then
            $repoDir || "/resources/fonts"
        else
            ()
};
