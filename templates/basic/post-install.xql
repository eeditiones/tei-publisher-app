xquery version "3.0";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "/db/apps/tei-simple/content/util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "/db/apps/tei-simple/content/odd2odd.xql";

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
    for $source in xmldb:get-child-resources($collection || "/resources/odd")[ends-with(., ".odd")]
    for $module in ("web", "print", "latex")
    for $file in pmu:process-odd(
        doc(odd:get-compiled($collection || "/resources/odd", $source, $collection || "/resources/odd/compiled")),
        $collection || "/transform",
        $module,
        "../transform",
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
        ),
        for $file in xmldb:get-child-resources($collection || "/resources/odd/compiled")
        let $path := xs:anyURI($collection || "/resources/odd/compiled/" || $file)
        return (
            sm:chown($path, $permissions/@user),
            sm:chgrp($path, $permissions/@group)
        )
    )
};

sm:chmod(xs:anyURI($target || "/modules/view.xql"), "rwsr-xr-x"),
(:sm:chmod(xs:anyURI($target || "/modules/transform.xql"), "rwsr-xr-x"),:)
sm:chmod(xs:anyURI($target || "/modules/pdf.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/get-epub.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/ajax.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/regenerate.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/upload.xql"), "rwsr-xr-x"),

(: LaTeX requires dba permissions to execute shell process :)
sm:chmod(xs:anyURI($target || "/modules/latex.xql"), "rwxr-Sr-x"),
sm:chgrp(xs:anyURI($target || "/modules/latex.xql"), "dba"),

local:generate-code($target)

