xquery version "3.1";

import module namespace pmc="http://www.tei-c.org/tei-simple/xquery/config";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

let $pmuConfig := pmc:generate-pm-config(($config:odd-available, $config:odd-internal), $config:default-odd, $config:odd-root)
return
    xmldb:store($config:app-root || "/modules", "pm-config.xql", $pmuConfig, "application/xquery")