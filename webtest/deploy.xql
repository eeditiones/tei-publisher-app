xquery version "3.1";

declare variable $local:REPO := "http://demo.exist-db.org/exist/apps/public-repo/modules/find.xql";

declare variable $local:PKG := "http://existsolutions.com/apps/tei-publisher";

let $isInstalled := repo:list()[. = $local:PKG]
let $uninstall :=
    if ($isInstalled) then (
        repo:undeploy($local:PKG),
        repo:remove($local:PKG)
    ) else
        ()
for $xar in xmldb:get-child-resources("/db/_pkgs")
return
    repo:install-and-deploy-from-db("/db/_pkgs/" || $xar, $local:REPO),
xmldb:remove("/db/_pkgs")