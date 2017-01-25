xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://www.tei-c.org/tei-simple/config";

import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Should documents be located by xml:id or filename?
 :)
declare variable $config:address-by-id := false();

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
 : The function to be called to determine the next content chunk to display.
 : It takes two parameters:
 :
 : * $elem as element(): the current element displayed
 : * $view as xs:string: the view, either 'div', 'page' or 'body'
 :)
declare variable $config:next-page := nav:get-next#3;

(:
 : The function to be called to determine the previous content chunk to display.
 : It takes two parameters:
 :
 : * $elem as element(): the current element displayed
 : * $view as xs:string: the view, either 'div', 'page' or 'body'
 :)
declare variable $config:previous-page := nav:get-previous#3;

(:
 : The CSS class to declare on the main text content div.
 :)
declare variable $config:css-content-class := "content";

(:
 : The domain to use for logged in users. Applications within the same
 : domain will share their users, so a user logged into application A
 : will be able to access application B.
 :)
declare variable $config:login-domain := "org.exist.tei-simple";

(:~
 : Configuration XML for Apache FOP used to render PDF. Important here
 : are the font directories.
 :)
declare variable $config:fop-config :=
    let $fontsDir := config:get-fonts-dir()
    return
        <fop version="1.0">
            <!-- Strict user configuration -->
            <strict-configuration>true</strict-configuration>

            <!-- Strict FO validation -->
            <strict-validation>false</strict-validation>

            <!-- Base URL for resolving relative URLs -->
            <base>./</base>

            <renderers>
                <renderer mime="application/pdf">
                    <fonts>
                    {
                        if ($fontsDir) then (
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="normal" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-Bold.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="normal" weight="700"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-Italic.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="italic" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/Junicode-BoldItalic.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Junicode" style="italic" weight="700"/>
                            </font>
                        ) else
                            ()
                    }
                    </fonts>
                </renderer>
            </renderers>
        </fop>
;

(:~
 : The command to run when generating PDF via LaTeX. Should be a sequence of
 : arguments.
 :)
declare variable $config:tex-command := function($file) {
    ( "/usr/local/bin/pdflatex", "-interaction=nonstopmode", $file )
};

(:~
 : Configuration for epub files.
 :)
 declare variable $config:epub-config := function($root as element(), $langParameter as xs:string?) {
     let $properties := tpu:parse-pi(root($root), ())
     return
         map {
             "metadata": map {
                 "title": $root/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/string(),
                 "creator": $root/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/string(),
                 "urn": util:uuid(),
                 "language": ($langParameter, $root/@xml:lang, $root/tei:teiHeader/@xml:lang, "en")[1]
             },
             "odd": $properties?odd,
             "output-root": $config:odd-root,
             "fonts": [
                 $config:app-root || "/resources/fonts/Junicode.ttf",
                 $config:app-root || "/resources/fonts/Junicode-Bold.ttf",
                 $config:app-root || "/resources/fonts/Junicode-BoldItalic.ttf",
                 $config:app-root || "/resources/fonts/Junicode-Italic.ttf"
             ]
         }
 };

(:~
 : Root path where images to be included in the epub can be found.
 : Leave as empty sequence if images can be located within the data
 : collection using relative path.
 :)
declare variable $config:epub-images-path := ();

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

declare variable $config:output := "transform";

declare variable $config:output-root := $config:app-root || "/" || $config:output;

declare variable $config:module-config := doc($config:odd-root || "/configuration.xml")/*;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Return an ID which may be used to look up a document. Change this if the xml:id
 : which uniquely identifies a document is *not* attached to the root element.
 :)
declare function config:get-id($node as node()) {
    root($node)/*/@xml:id
};

(:~
 : Returns a path relative to $config:data-root used to locate a document in the database.
 :)
declare function config:get-relpath($node as node()) {
    substring-after(document-uri(root($node)), $config:data-root || "/")
};

declare function config:get-identifier($node as node()) {
    if ($config:address-by-id) then
        config:get-id($node)
    else
        config:get-relpath($node)
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
