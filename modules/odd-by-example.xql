xquery version "3.1";
(:~
 : odd-by-example takes an example TEI file and constructs a custom odd
 : describing the classes and elemenets used by the example input.
 :
 : @author Duncan Paterson
 : @version 0.1
 : @see http://teic.github.io/TCW/howtoGenerate.html
 : @see https://github.com/TEIC/Stylesheets/blob/dev/tools/oddbyexample.xsl
 :
 : @return myGenerated.odd:)

declare namespace obe="teipublisher.com/obe";
declare namespace xsl="http://www.w3.org/1999/XSL/Transform";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare variable $obe:test := doc($config:data-root || '/test/' || 'graves6.xml');

(:~
 : obe:process-example takes all TEI files in a given collection and stores
 : a customized odd.
 :
 : @param $example a document within the collectino to process
 : @param $name-prefix the prefix for the output file-name
 :
 : @returns a custom odd file in the odd collection of tei-publisher
 :)
declare function obe:process-example ($example as item()?, $name-prefix as xs:string) as item()* {
let $xsl := doc('oddbyexample.xsl')
let $output := $name-prefix || 'Generated.odd'
let $parameters :=
  <parameters>
    <param name="corpus" value="."/>
    <param name ="schema" value="oddbyexample"/>
  </parameters>
let $attributes :=
  <attributes>
    <attr name="http://saxon.sf.net/feature/initialTemplate" value="main"/>
  </attributes>
let $serialize := "method=xml media-type=text/xml omit-xml-declaration=no indent=yes"

return
   xmldb:store($config:odd-root, $output, transform:transform($example, $xsl, $parameters, $attributes, $serialize))
};

   obe:process-example($obe:test, 'test')
