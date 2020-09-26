xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

declare function api:lookup($name as xs:string) {
    try {
        function-lookup(xs:QName($name), 1)
    } catch * {
        ()
    }
};