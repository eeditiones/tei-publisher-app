xquery version "3.1";

module namespace cutil="http://teipublisher.com/api/cache";

import module namespace router="http://e-editiones.org/roaster";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";

declare function cutil:check-last-modified($request as map(*), $nodes as node()*, $callback as function(*)) {
    if ($config:enable-proxy-caching) then (
        util:log('INFO', 'If-Modified-Since: ' || $request?parameters?If-Modified-Since),
        let $ifModifiedSince :=
            if (map:contains($request?parameters, 'If-Modified-Since')) then
                $request?parameters?If-Modified-Since => parse-ietf-date()
            else
                ()
        let $lastModified :=
            for $node in $nodes
            let $modified :=
                xmldb:last-modified(util:collection-name($node), util:document-name($node))
            order by $modified descending
            return
                $modified
        let $shouldReturn304 :=
            if (exists($ifModifiedSince)) then
                $ifModifiedSince ge
                    $lastModified
                    (: For the purpose of comparing the resource's last modified date with the If-Modified-Since
                    : header supplied by the client, we must truncate any milliseconds from the last modified date.
                    : This is because HTTP-date is only specific to the second.
                    : @see https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1 :)
                    => format-dateTime("[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01][Z]")
                    => xs:dateTime()
            else
                ()
        return (
            if(string-length($lastModified) >0) 
            then (response:set-header("Last-Modified", cutil:format-http-date(head($lastModified)))) 
            else (),        
            if ($shouldReturn304) then
                router:response(304, "", "")
            else
                $callback($request, $nodes)
        )
    ) else
        $callback($request, $nodes)
};

declare function cutil:format-http-date($dateTime as xs:dateTime) as xs:string {
    $dateTime
    => adjust-dateTime-to-timezone(xs:dayTimeDuration("PT0H"))
    => format-dateTime("[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] [Z0000]", "en", (), ())
};