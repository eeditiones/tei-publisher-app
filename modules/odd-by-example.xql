xquery version "3.1";
(:~
 : odd-by-example includes functions for constructing customized ODD files
 : using uploaded TEI files as input for use with tei-publisher.
 :
 : It uses the familar xsl stylesheet transformations
 : distributed by the tei consortium at https:github.com/TEIC/Stylesheets
 :
 : @author Duncan Paterson
 : @version 1.0.0
 : @see http://teic.github.io/TCW/howtoGenerate.html
 : @see https://github.com/TEIC/Stylesheets/blob/dev/tools/oddbyexample.xsl
 :
 : @return someGenerated.odd:)

module namespace obe = "http://exist-db.org/apps/teipublisher/obe";
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace config = "http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";

(:~
 : odd-by-example requires a compiled version of the base odd, which we need to
 : create ourselves for anything but tei_all
 :
 : @see https://github.com/TEIC/Stylesheets/issues/319
 :
 : @param $path to the odd file to be compiled
 : @param $out-prefix the file name prefix "some" for "someSubset.xml"
 :
 : @return someSubset.xml
 :)
declare function obe:compile-odd($path as item(), $out-prefix as xs:string) as item() {
    let $xsl := doc('odd2odd.xsl')
    let $file-name := $out-prefix || 'Subset.xml'
    let $parameter := ()
    return
        xmldb:store($config:odd-root, $file-name, transform:transform($path, $xsl, $parameter))
};

declare function obe:make-catalog($col as item()*, $docs as xs:string*) as item() {
    <collection stable="true" xml:base="xmldb:exist://">
        {
            if (exists($docs)) then
                for $doc in $docs
                return
                    <doc href="{$config:data-root || "/" || $doc}"/>
            else
                for $doc in collection($col)//tei:TEI
                return
                    <doc href="{document-uri(root($doc))}"/>
        }
    </collection>
};

(:~
 : obe:process-example takes all TEI files in a given collection and stores
 : a customized odd.
 :
 : @param $sample-path the xpath to the collection containing the example TEI files as xs:string
 : @param $name-prefix for output file, e.g. "my" for "myGenerated.odd"
 : @param $odd_base the URI of the defaultSource paramater
 :
 : @return a custom odd file in the odd collection of tei-publisher
 :)
declare function obe:process-example($sample-path as xs:string, $name-prefix as xs:string, $odd_base as xs:string?,
    $docs as xs:string*, $title as xs:string?) as item()* {

    (: we need to create this file on the fs for the xsl transform to work it will immediately removed to avoid permission collisions:)
    let $catalog := xmldb:store($sample-path, 'catalog.xml', obe:make-catalog($sample-path, $docs))
    let $sax-cat := 'xmldb:exist://' || document-uri(collection($sample-path)//root(collection))

    let $xsl := doc('oddbyexample.xsl')
    let $output := $name-prefix || '.odd'
    let $base := switch ($odd_base)
        case ('simplePrint')
        case ('simple')
            return
                xs:anyURI('xmldb:exist:///db/apps/tei-publisher/odd/tei_simplePrintSubset.xml')
        case ('publisher')
            return
                xs:anyURI('xmldb:exist:///db/apps/tei-publisher/odd/teipublisherSubset.xml')
        case ('all')
        case ('P5')
            return
                'http://www.tei-c.org/Vault/P5/current/xml/tei/odd/p5subset.xml'
        default return
            'http://www.tei-c.org/Vault/P5/current/xml/tei/odd/p5subset.xml'
    let $source :=
        switch ($odd_base)
            case 'simplePrint'
            case 'simple' return
                'tei_simplePrint.odd'
            default return
                'teipublisher.odd'
let $parameters :=
<parameters>
    <!-- name of odd -->
    <param name="schema" value="{substring-before($output, '.odd')}"/>
    <!-- whether to do all the global attributes -->
    <param name="keepGlobals" value="true"/>
    <!-- the document corpus -->
    <param name="corpus" value="{$sax-cat}"/>
    <!-- file names starting with what prefix? -->
    <param name="prefix" value=""/>
    <!-- the source of the TEI (just needs *Spec)-->
    <param name="defaultSource" value="{$base}"/>
    <!-- should elements in teiHeader be included?-->
    <param name="includeHeader" value="true"/>
    <!-- should we make valList for @rend and @rendition -->
    <param name="enumerateRend" value="true"/>
    <!-- should we make valList for @type -->
    <param name="enumerateType" value="true"/>
    <!-- should we deal with non-TEI namespaces -->
    <param name="processNonTEI" value="false"/>
    <!-- do you want moduleRef generated with @include or @except? -->
    <!-- seems broken see https://github.com/TEIC/Stylesheets/issues/212 -->
    <param name="method" value="include"/>
    <!-- turn on debug messages -->
    <param name="debug" value="false"/>
    <!-- turn on messages -->
    <param name="verbose" value="false"/>
    <!-- which files to look at? provide suffix -->
    <param name="suffix" value="xml"/>
    <!-- should P4 files be considered? -->
    <param name="processP4" value="false"/>
    <!-- should P5 files be considered? -->
    <param name="processP5" value="true"/>
</parameters>

let $attributes :=
<attributes>
    <attr name="http://saxon.sf.net/feature/initialTemplate" value="main"/>
</attributes>

let $serialize := "method=xml media-type=text/xml omit-xml-declaration=no indent=yes"
let $publisherODD := odd:compile($config:odd-root, "teipublisher.odd")
let $transformed := obe:merge(transform:transform(doc($sax-cat), $xsl, $parameters, $attributes, $serialize), $source, $title, $publisherODD)
return
    (xmldb:store($config:odd-root, $output, $transformed),
    xmldb:remove($sample-path, 'catalog.xml'))
};

declare function obe:merge($nodes as node()*, $base as xs:string, $title as xs:string?, $publisherODD as node()) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    obe:merge($node/node(), $base, $title, $publisherODD)
                }
            case element(tei:title) return
                if ($node/@type = 'short') then
                    $node
                else
                    element { node-name($node) } {
                        $title
                    }
            case element(tei:elementSpec) return
                let $publisherModels := $publisherODD//tei:elementSpec[@ident = $node/@ident]/(tei:model|tei:modelGrp|tei:modelSequence)
                return
                    if ($publisherModels) then
                        element { node-name($node) } {
                            $node/@*,
                            $node/* except ($node/tei:exemplum|$node/tei:remarks|$node/tei:listRef),
                            $publisherModels,
                            ($node/tei:exemplum,$node/tei:remarks,$node/tei:listRef)
                        }
                    else
                        $node
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    obe:merge($node/node(), $base, $title, $publisherODD)
                }
            default return $node
};
