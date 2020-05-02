xquery version "3.0";

import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "modules/navigation.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

if (not(sm:user-exists("tei-demo"))) then
    sm:create-account("tei-demo", "demo", "tei", ())
else
    (),
sm:chmod(xs:anyURI($target || "/modules/view.xql"), "rwxr-Sr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/transform.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/pdf.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/epub.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/components.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/lib/components-odd.xql"), "rwxr-xr-x"),
(: sm:chmod(xs:anyURI($target || "/modules/lib/upload.xql"), "rwsr-xr-x"), :)
(: sm:chmod(xs:anyURI($target || "/modules/lib/regenerate.xql"), "rwxr-xr-x"), :)
sm:chmod(xs:anyURI($target || "/modules/lib/dts.xql"), "rwsr-xr-x"),

(: LaTeX requires dba permissions to execute shell process :)
sm:chmod(xs:anyURI($target || "/modules/lib/latex.xql"), "rwsr-Sr-x"),
sm:chown(xs:anyURI($target || "/modules/lib/latex.xql"), "tei"),
sm:chgrp(xs:anyURI($target || "/modules/lib/latex.xql"), "dba"),

(: App generator requires dba permissions to install packages :)
sm:chmod(xs:anyURI($target || "/modules/components-generate.xql"), "rwsr-Sr-x"),
sm:chown(xs:anyURI($target || "/modules/components-generate.xql"), "tei"),
sm:chgrp(xs:anyURI($target || "/modules/components-generate.xql"), "dba"),

xmldb:create-collection($target || "/data", "playground"),
sm:chmod(xs:anyURI($target || "/data/playground"), "rwxrwxr-x"),
sm:chown(xs:anyURI($target || "/data/playground"), "tei-demo"),
sm:chgrp(xs:anyURI($target || "/data/playground"), "tei"),
xmldb:create-collection($target || "/data", "temp"),
sm:chmod(xs:anyURI($target || "/data/temp"), "rwxrwxr-x"),
sm:chmod(xs:anyURI($target || "/odd"), "rwxrwxr-x"),
sm:chmod(xs:anyURI($target || "/transform"), "rwxrwxr-x")