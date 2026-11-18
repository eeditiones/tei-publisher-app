xquery version "3.1";

(:~
 : Target of the controller for requests rejected before routing,
 : e.g. because they contain ".." path segments.
 :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

response:set-status-code(400),
map {
    "code": 400,
    "description": "Invalid request: path segments '..' are not allowed"
}
