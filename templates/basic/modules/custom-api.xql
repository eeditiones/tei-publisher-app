xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace custom-api="http://teipublisher.com/api/custom";

(: Add your own module imports here :)
import module namespace rutil="http://exist-db.org/xquery/router/util";
import module namespace app="teipublisher.com/app" at "app.xql";

(:~
 : list of additional definition files to use
 : modules/lib/api.json will be appended 
 :)
declare variable $custom-api:definitions := ("modules/custom-api.json");

(:~
 : Keep this! This function will resolve route handlers from modules imported here
 :)
declare function custom-api:lookup($name as xs:string, $arity as xs:integer) as function(*)? {
    function-lookup(xs:QName($name), $arity)
};
