xquery version "3.0";

module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

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
    let $compiled := odd:compile($inputCol, $odd)
    return
        xmldb:store($outputCol, $odd, $compiled, "application/xml")
};

declare function odd:compile($inputCol as xs:string, $odd as xs:string) {
    let $root := doc($inputCol || "/" || $odd)/tei:TEI
    return
        if ($root) then
            if ($root//tei:schemaSpec[@source]) then
                let $import := $root//tei:schemaSpec[@source][1]
                let $name := $import/@source
                let $parent := odd:compile($inputCol, $name)
                return
                    odd:merge($parent, $root)
            else
                $root
        else
            error(xs:QName("odd:not-found"), "ODD not found: " || $inputCol || "/" || $odd)
};

declare %private function odd:merge($parent as element(tei:TEI), $child as element(tei:TEI)) {
    <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xml:lang="en">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>Merged TEI PM Spec</title>
                </titleStmt>
                <publicationStmt>
                    <p>Automatically generated, do not modify.</p>
                </publicationStmt>
                <sourceDesc>
                    <p>Generated from input ODD: {document-uri(root($child))}</p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
        <text>
            <body>
            {
                (: Copy element specs which are not overwritten by child :)
                for $spec in $parent//elementSpec
                let $childSpec := $child//elementSpec[@ident = $spec/@ident][@mode = "change"]
                return
                    if ($childSpec) then
                        $childSpec
                    else if ($spec//model) then
                        $spec
                    else
                        ()
            }
            {
                (: Copy added element specs :)
                for $spec in $child//elementSpec[.//model]
                (: Skip specs which already exist in parent :)
                where empty($parent//elementSpec[@ident = $spec/@ident])
                return
                    $spec
            }
            {
                (: Merge global outputRenditions :)
                for $rendition in $child//outputRendition[@xml:id][not(ancestor::model)]
                where exists($parent/id($rendition/@xml:id))
                return
                    $rendition,
                for $parentRendition in $parent//outputRendition[@xml:id][not(ancestor::model)]
                where empty($child/id($parentRendition/@xml:id))
                return
                    $parentRendition
            }
            </body>
        </text>
    </TEI>
};

(:~ Strip out documentation elements to speed things up :)
declare %private function odd:strip-down($nodes as node()*) {
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
