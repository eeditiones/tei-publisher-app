xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "/db/apps/tei-simple/content/util.xql";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "/db/apps/tei-simple/content/odd2odd.xql";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

<div>
    <h4>Regenerated XQuery code from ODD files</h4>
    <ul>
    {
        for $source in $config:odd
        for $module in ("web", "print", "latex")
        for $file in pmu:process-odd(
            doc(odd:get-compiled($config:odd-root, $config:odd, $config:compiled-odd-root)),
            $config:output-root,
            $module,
            "../" || $config:output,
            $config:module-config)?("module")
        return
            <li>{$file}</li>
    }
    </ul>
</div>