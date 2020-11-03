xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://existsolutions.com/dipf/doi/config";

import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";


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


(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    doc(concat($config:app-root, "/repo.xml"))/repo:meta
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package
};

declare function config:get-configuration() as element(configuration) {
    doc(concat($config:app-root, "/configuration.xml"))/configuration
};

declare function config:access-allowed($path as xs:string, $user as xs:string) as xs:boolean {
    if (sm:is-dba($user)) then
        true()
    else
        let $deny := config:get-configuration()/restrictions/deny
        return
            if ($deny) then
                not(
                    some $denied in $deny/@collection
                    satisfies starts-with($path, $denied)
                )
            else
                true()
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare %templates:wrap function config:app-info($node as node(), $model as map(*)) {
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
        </table>
};

(:~
 : Returns the title of the current application
 :)
declare %templates:wrap function config:app-title($node as node(), $model as map(*))  {
    "DIPF DOI App"
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="bla"/>    
};

