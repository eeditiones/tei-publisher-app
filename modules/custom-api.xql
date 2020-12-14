xquery version "3.1";

module namespace custom-api="http://teipublisher.com/api/custom";

import module namespace bapi="http://teipublisher.com/api/blog" at "blog.xql";
import module namespace rutil="http://exist-db.org/xquery/router/util";

(:~
 : list of additional definition files to use
 : modules/lib/api.json will be appended 
 :)
declare variable $custom-api:definitions := ("modules/custom-api.json");

(:~
 : This function will resolve route handlers from modules imported here
 :)
declare function custom-api:lookup($name as xs:string, $arity as xs:integer) as function(*)? {
    function-lookup(xs:QName($name), $arity)
};
