xquery version "3.1";
(:~
 : odd-by-example includes functions for construcing customized ODD files
 : using uploaded TEI files as input for use with tei-publisher.
 :
 : It uses the familar xsl stylesheet transformations
 : distributed by the tei consortium at https:github.com/TEIC/Stylesheets
 :
 : @author Duncan Paterson
 : @version 0.1
 : @see http://teic.github.io/TCW/howtoGenerate.html
 : @see https://github.com/TEIC/Stylesheets/blob/dev/tools/oddbyexample.xsl
 :
 : @return someGenerated.odd:)

declare namespace obe="teipublisher.com/obe";
declare namespace xsl="http://www.w3.org/1999/XSL/Transform";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare variable $obe:test := doc($config:data-root || '/test/' || 'graves6.xml');

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
declare function obe:compile-odd ($path as item(), $out-prefix as xs:string) as item() {
let $xsl := doc('odd2odd.xsl')
let $file-name := $out-prefix || 'Subset.xml'
let $parameter := ()
return
  xmldb:store($config:odd-root, $file-name, transform:transform($path, $xsl, $parameter))
};

(:~
 : obe:process-example takes all TEI files in a given collection and stores
 : a customized odd.
 :
 : @param $example a document within the collectino to process
 : @param $name-prefix for output file, e.g. "my" for "myGenerated.odd"
 : @param $odd-base the URI of the defaultSource paramater
 :
 : @return a custom odd file in the odd collection of tei-publisher
 :)
declare function obe:process-example ($example as item()?, $name-prefix as xs:string, $odd-base as xs:string?) as item()* {
let $xsl := doc('oddbyexample.xsl')
let $output := $name-prefix || 'Generated.odd'
let $base := switch ($odd-base)
  case ('simplePrint') case ('simple')
    return xs:anyURI('xmldb:exist:///db/apps/tei-publisher/odd/tei_simplePrintSubset.xml')
  case ('publisher')
    return xs:anyURI('xmldb:exist:///db/apps/tei-publisher/odd/teipublisherSubset.xml')
  case ('all') case ('P5')
    return 'http://www.tei-c.org/Vault/P5/current/xml/tei/odd/p5subset.xml'
  default return 'http://www.tei-c.org/Vault/P5/current/xml/tei/odd/p5subset.xml'

let $parameters :=
  <parameters>
    <!-- the document corpus -->
    <param name="corpus" value="."/>
    <!-- name of odd -->
    <param name="schema" value="{substring-before($output, '.odd')}"/>
    <!-- the source of the TEI (just needs *Spec)-->
    <param name="defaultSource" value="{$base}"/>
    <!-- should we make valList for @rend and @rendition -->
    <param name="enumerateRend" value="false"/>
    <!-- whether to do all the global attributes -->
    <param name="keepGlobals" value="true"/>
    <!-- should elements in teiHeader be included?-->
    <param name="includeHeader" value="true"/>
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

return
   xmldb:store($config:odd-root, $output, transform:transform($example, $xsl, $parameters, $attributes, $serialize))
};

  (: obe:compile-odd(doc('../odd/tei_simplePrint.odd'), 'tei_simplePrint') :)
  obe:process-example($obe:test, 'a_simple_test', 'simple')

(: exists('db/apps/tei-publisher/odd/tei_simplePrintSubset.xml') :)
