xquery version "3.0";

module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare variable $odd:XSL := doc($config:app-root || "/resources/xsl/odd2odd.xsl");

declare function odd:get-compiled($inputCol as xs:string, $odd as xs:string, $outputCol as xs:string) as xs:string {
    if (doc-available($outputCol || "/" || $odd)) then
        let $last-modified := xmldb:last-modified($inputCol, $odd)
        return
            if ($last-modified > xmldb:last-modified($outputCol, $odd)) then
                odd:compile($inputCol, $odd, $outputCol)
            else
                $outputCol || "/" || $odd
    else
        odd:compile($inputCol, $odd, $outputCol)
};

declare function odd:compile($inputCol as xs:string, $odd as xs:string, $outputCol as xs:string) {
    console:log("Compiling odd: " || $inputCol || "/" || $odd || " to " || $outputCol),
    let $root := doc($inputCol || "/" || $odd)/tei:TEI
    return 
        if ($root) then (
            for $import in $root//tei:schemaSpec[@source]
            let $name := $import/@source
            let $log := console:log("Loading imported odd: " || $name)
            return
                odd:get-compiled($inputCol, $name, $outputCol)[2],
            let $params :=
                <parameters>
                    <param name="currentDirectory" value="xmldb:exist://{$outputCol}"/>
                    <param name="lang" value="en"/>
                    <param name="exist:stop-on-warn" value="yes"/>
                    <param name="exist:stop-on-error" value="yes"/>
                </parameters>
            let $compiled := transform:transform($root, $odd:XSL, $params)
            let $stored :=
                if (exists($compiled)) then
                    xmldb:store($outputCol, $odd, odd:strip-down($compiled), "application/xml")
                else
                    ()
            return
                $stored
        ) else
            error(xs:QName("odd:not-found"), "ODD not found: " || $inputCol || "/" || $odd)
};

(:~ Strip out documentation elements to speed things up :)
declare function odd:strip-down($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case processing-instruction() | element(tei:remarks) | element(tei:exemplum) | element(tei:listRef) | element(tei:gloss) return
                ()
            case element(tei:desc) return
                if ($node/parent::tei:model) then
                    $node
                else
                    ()
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    odd:strip-down($node/node())
                }
            default return
                $node
};