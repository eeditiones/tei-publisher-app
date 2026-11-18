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
        "message": "recreated pm-config.xql",
        "files": map {
            "modules/pm-config.xql": $pmuConfig
        }
    }
};

declare %private function action:generate-code() {
    (:
        In-memory copy of configuration.xml for pmu:process-odd ($config/*:module).
        If that step is empty, pmu falls back to config.xqm as "global". See post-install.xql.
    :)
    let $modulesConfig := util:expand(doc($config:app-root || "/resources/odd/configuration.xml"))/*
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
            $modulesConfig,
            $module = "web"
        )
    return
        action:report-odd-status($report, $module),
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

(:~
 : Report the result of compiling one ODD for one output mode. On failure, the previously
 : compiled version stays active and the generated code is kept in a .invalid.xql file.
 :)
declare %private function action:report-odd-status($report as map(*), $mode as xs:string) {
    let $invalid := $report?id || "-" || $mode || ".invalid.xql"
    return
        if ($report?error) then
            let $error := ($report?error//error)[1]
            let $line := xs:integer(($error/@line, 0)[1])
            let $lines := tokenize($report?code, "\n")
            return
                map {
                    "type": "error",
                    "message":
                        "Code generated from " || $report?id || ".odd for " || $mode || " doesn't compile, " ||
                        "the previous version stays active: " || normalize-space($error),
                    "path": "transform/" || $invalid,
                    "line": $line,
                    "column": xs:integer(($error/@column, 0)[1]),
                    "code": string-join(
                        for $n in max((1, $line - 3)) to min((count($lines), $line + 3))
                        return
                            $n || ": " || $lines[$n],
                        "&#10;"
                    )
                }
        else (
            if (util:binary-doc-available($config:app-root || "/transform/" || $invalid)) then
                xmldb:remove($config:app-root || "/transform", $invalid)
            else
                (),
            map {
                "type": "update",
                "message": $report?module
            }
        )
};
