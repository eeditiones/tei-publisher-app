(:
 :  Copyright (C) 2017 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

module namespace query="http://www.tei-c.org/tei-simple/query";

import module namespace tei-query="http://www.tei-c.org/tei-simple/query/tei" at "tei-query.xql";
import module namespace docbook-query="http://www.tei-c.org/tei-simple/query/docbook" at "db-query.xql";

declare %private function query:dispatch($config as map(*), $function as xs:string, $args as array(*)) {
    let $fn := function-lookup(xs:QName($config?type || "-query:" || $function), array:size($args))
    return
        if (exists($fn)) then
            apply($fn, $args)
        else
            ()
};

(:~
 : Query the data set.
 :
 : @param $fields a sequence of field names describing the type of content to query,
 :  e.g. "heading" or "text"
 : @param $query the query string
 : @param $target-texts a sequence of identifiers for texts to query. May be empty.
 :)
declare function query:query-default($fields as xs:string+, $query as xs:string,
    $target-texts as xs:string*) {
    tei-query:query-default($fields, $query, $target-texts),
    docbook-query:query-default($fields, $query, $target-texts)
};

declare function query:query-metadata($field as xs:string, $query as xs:string, $sort as xs:string) {
    tei-query:query-metadata($field, $query, $sort),
    docbook-query:query-metadata($field, $query, $sort)
};

declare function query:get-parent-section($config as map(*), $node as node()) {
    query:dispatch($config, "get-parent-section", [$node])
};

declare function query:get-breadcrumbs($config as map(*), $hit as element(), $parent-id as xs:string) {
    query:dispatch($config, "get-breadcrumbs", [$config, $hit, $parent-id])
};

declare function query:expand($config as map(*), $data as element()) {
    query:dispatch($config, "expand", [$data])
};

declare function query:get-current($config as map(*), $div as element()?) {
    query:dispatch($config, "get-current", [$config, $div])
};

declare function query:autocomplete($doc as xs:string?, $fields as xs:string+, $q as xs:string) {
    tei-query:autocomplete($doc, $fields, $q),
    docbook-query:autocomplete($doc, $fields, $q)
};
