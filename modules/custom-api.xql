xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

import module namespace bapi="http://teipublisher.com/api/blog" at "blog.xql";
import module namespace rutil="http://exist-db.org/xquery/router/util";

declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};