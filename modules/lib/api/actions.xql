xquery version "3.1";

module namespace action="http://teipublisher.com/api/actions";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace pmc="http://www.tei-c.org/tei-simple/xquery/config";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare namespace repo="http://exist-db.org/xquery/repo";

declare variable $action:repoxml :=
    let $uri := doc($config:app-root || "/expath-pkg.xml")/*/@name
    let $repo := util:binary-to-string(repo:get-resource($uri, "repo.xml"))
    return
        parse-xml($repo)
;

declare function action:fix-odds($request as map(*)) {
    action:generate-pm-config(),
    action:generate-code()
};

declare %private function action:generate-pm-config() {
    let $pmuConfig := pmc:generate-pm-config(($config:odd-available, $config:odd-internal), $config:default-odd, $config:odd-root, $config:odd-media)
    let $_ := xmldb:store($config:app-root || "/modules", "pm-config.xql", $pmuConfig, "application/xquery")
    return map {
        "type": "action:fix-odds",
        "message": "recreated pm-config.xql"
    }
};

declare %private function action:generate-code() {
    for $source in ($config:odd-available, $config:odd-internal)
    let $odd := doc($config:app-root || "/resources/odd/" || $source)
    let $pi := tpu:parse-pi($odd, (), $source)
    for $module in
        if ($pi?output) then
            tokenize($pi?output)
        else
            $config:odd-media
    let $report :=
        pmu:process-odd (
            (:    $odd as document-node():)
            odd:get-compiled($config:app-root || "/resources/odd" , $source),
            (:    $output-root as xs:string    :)
            $config:app-root || "/transform",
            (:    $mode as xs:string    :)
            $module,
            (:    $relPath as xs:string    :)
            "transform",
            (:    $config as element(modules)?    :)
            doc($config:app-root || "/resources/odd/configuration.xml")/*,
            $module = "web"
        )
    return
        action:report-odd-status($report),
    let $permissions := $action:repoxml//repo:permissions[1]
    return (
        for $file in xmldb:get-child-resources($config:app-root || "/transform")
        let $path := xs:anyURI($config:app-root || "/transform/" || $file)
        return (
            sm:chown($path, $permissions/@user),
            sm:chgrp($path, $permissions/@group)
        )
    )
};

declare %private function action:report-odd-status($report) {
    map {
        "type": if ($report?error) then "conflict" else "update",
        "message": $report?module
    }
};