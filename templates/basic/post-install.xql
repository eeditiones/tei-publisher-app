xquery version "3.0";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare namespace repo="http://exist-db.org/xquery/repo";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;


declare variable $repoxml :=
    let $uri := doc($target || "/expath-pkg.xml")/*/@name
    let $repo := util:binary-to-string(repo:get-resource($uri, "repo.xml"))
    return
        parse-xml($repo)
;

declare function local:generate-code($collection as xs:string) {
    let $odd := xmldb:get-child-resources($collection || "/resources/odd")[ends-with(., ".odd")]
    let $count := count($odd)
    let $oddName := 
        switch ($count)
            case 2 return distinct-values($odd[not(.=("tei_simplePrint.odd"))])            
            case 1 return $odd
        default return  distinct-values($odd[not(.=("teipublisher.odd", "tei_simplePrint.odd"))])
    
(: TODO: cleanup   
   for $source in $collection || "/resources/odd" || $oddName
   for $source in xmldb:get-child-resources($collection || "/resources/odd")[ends-with(., ".odd")]:)
   
    for $module in ("web", "print", "latex", "epub")
    for $file in pmu:process-odd (
        (:    $odd as document-node():)
        odd:get-compiled($collection || "/resources/odd" , $oddName),
        (:    $output-root as xs:string    :)
        $collection || "/transform",
        (:    $mode as xs:string    :)
        $module,
        (:    $relPath as xs:string    :)
        "../transform",
        (:    $config as element(modules)?    :)
        doc($collection || "/resources/odd/configuration.xml")/*)?("module")
    return 
        (),
    let $permissions := $repoxml//repo:permissions[1]
    return (
        for $file in xmldb:get-child-resources($collection || "/transform")
        let $path := xs:anyURI($collection || "/transform/" || $file)
        return (
            sm:chown($path, $permissions/@user),
            sm:chgrp($path, $permissions/@group)
        )
    )
};

sm:chmod(xs:anyURI($target || "/modules/view.xql"), "rwsr-xr-x"),
(:sm:chmod(xs:anyURI($target || "/modules/transform.xql"), "rwsr-xr-x"),:)
sm:chmod(xs:anyURI($target || "/modules/lib/pdf.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/get-epub.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/ajax.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/regenerate.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/upload.xql"), "rwsr-xr-x"),

(: LaTeX requires dba permissions to execute shell process :)
sm:chmod(xs:anyURI($target || "/modules/lib/latex.xql"), "rwxr-Sr-x"),
sm:chgrp(xs:anyURI($target || "/modules/lib/latex.xql"), "dba"),

local:generate-code($target)

