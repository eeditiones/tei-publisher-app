xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

import module namespace bapi="http://teipublisher.com/api/blog" at "blog.xql";

declare function api:lookup($name as xs:string) {
    try {
        function-lookup(xs:QName($name), 1)
    } catch * {
        ()
    }
};