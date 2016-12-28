xquery version "3.0";

module namespace trigger="http://exist-db.org/xquery/trigger";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare variable $local:odd external;

declare variable $local:collection external;

declare function trigger:after-update-document($uri as xs:anyURI) {
    util:log("INFO", "trigger on " || $uri || " using " || $local:collection),
    if (ends-with($uri, ".odd")) then
        for $source in $local:odd
        for $module in ("web", "print", "latex")
        for $file in pmu:process-odd(
            doc(odd:get-compiled($local:collection || "/resources/odd", $local:odd, $local:collection || "/resources/odd/compiled")),
            $local:collection || "/transform",
            $module,
            "../transform",
            doc($local:collection || "/resources/odd/configuration.xml")/*)?("module")
        return
            ()
    else
        ()
};
