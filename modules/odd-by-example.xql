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

 module namespace obe ="teipublisher.com/obe";

 declare function obe:process ($example as item()) as item()* {
   xsl:transform
 };
