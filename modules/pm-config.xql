xquery version "3.0";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";

declare variable $pm-config:web-transform := pm-config:process(?, ?, ?, "web");
declare variable $pm-config:print-transform := pm-config:process(?, ?, ?, "print");
declare variable $pm-config:fo-transform := pm-config:process(?, ?, ?, "fo");
declare variable $pm-config:latex-transform := pm-config:process(?, ?, ?, "latex");
declare variable $pm-config:epub-transform := pm-config:process(?, ?, ?, "epub");
declare variable $pm-config:tei-transform := pm-config:process(?, ?, ?, "tei");

declare function pm-config:process($xml as node()*, $parameters as map(*)?, $odd as xs:string?, $outputMode as xs:string) {
    let $oddName := ($odd, $config:default-odd)[1]
    return
        pmu:process($config:odd-root || "/" || $oddName, $xml, $config:output-root, $outputMode,
            "../" || $config:output, $config:module-config, $parameters)
};
