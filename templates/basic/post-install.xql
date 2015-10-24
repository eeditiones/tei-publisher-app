xquery version "3.0";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

sm:chmod(xs:anyURI($target || "/modules/view.xql"), "rwsr-xr-x"),
(:sm:chmod(xs:anyURI($target || "/modules/transform.xql"), "rwsr-xr-x"),:)
sm:chmod(xs:anyURI($target || "/modules/pdf.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/get-epub.xql"), "rwsr-xr-x"),
sm:chmod(xs:anyURI($target || "/modules/ajax.xql"), "rwsr-xr-x"),

(: LaTeX requires dba permissions to execute shell process :)
sm:chmod(xs:anyURI($target || "/modules/latex.xql"), "rwxr-Sr-x"),
sm:chgrp(xs:anyURI($target || "/modules/latex.xql"), "dba")