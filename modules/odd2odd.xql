xquery version "3.0";

module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $odd:XSL := doc($config:app-root || "/resources/xsl/odd2odd.xsl");

declare function odd:get-compiled($odd as xs:string) as xs:string {
    if (doc-available($config:compiled-odd-root || "/" || $odd)) then
        let $last-modified := xmldb:last-modified($config:odd-root, $odd)
        return
            if ($last-modified > xmldb:last-modified($config:compiled-odd-root, $odd)) then
                odd:compile($odd)
            else
                $config:compiled-odd-root || "/" || $odd
    else
        odd:compile($odd)
};

declare function odd:compile($input as xs:string) {
    console:log("Compiling odd: " || $input || " to " || $config:compiled-odd-root),
    let $root := doc($config:odd-root || "/" || $input)/tei:TEI
    return 
        if ($root) then (
            for $import in $root//tei:schemaSpec[@source]
            let $name := $import/@source
            let $log := console:log("Loading imported odd: " || $name)
            return
                odd:get-compiled($name)[2],
            let $params :=
                <parameters>
                    <param name="currentDirectory" value="xmldb:exist://{$config:compiled-odd-root}"/>
                    <param name="lang" value="en"/>
                    <param name="exist:stop-on-warn" value="yes"/>
                    <param name="exist:stop-on-error" value="yes"/>
                </parameters>
            let $compiled := transform:transform($root, $odd:XSL, $params)
            let $stored :=
                if (exists($compiled)) then
                    xmldb:store($config:compiled-odd-root, $input, serialize($compiled), "application/xml")
                else
                    ()
            return
                $stored
        ) else
            error(xs:QName("odd:not-found"), "ODD not found: " || $config:odd-root || "/" || $input)
};