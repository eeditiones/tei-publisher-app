xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $allowOrigin := local:allowOriginDynamic(request:get-header("Origin"));

declare function local:allowOriginDynamic($origin as xs:string?) {
    let $origin := replace($origin, "^(\w+://[^/]+).*$", "$1")
    return
        if (local:checkOriginWhitelist($config:origin-whitelist, $origin)) then
            $origin
        else
            "*"
};

declare function local:checkOriginWhitelist($regexes, $origin) {
    if (empty($regexes)) then
        false()
    else if (matches($origin, head($regexes))) then
        true()
    else
        local:checkOriginWhitelist(tail($regexes), $origin)
};

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>

else if (matches($exist:path, "^.*/(resources|transform|modules|templates)/.*$")
    or (matches($exist:path, "^.*/odd/.*\.css$"))) then
    let $dir := replace($exist:path, "^.*/(resources|transform|modules|templates|odd)/.*$", "$1")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/{$dir}/{substring-after($exist:path, '/' || $dir || '/')}">
            {
                if ($dir = "transform") then
                    <set-header name="Cache-Control" value="no-cache"/>
                else if (contains($exist:path, "/resources/fonts/")) then
                    <set-header name="Cache-Control" value="max-age=31536000"/>
                else (
                    <set-header name="Access-Control-Allow-Origin" value="{$allowOrigin}"/>,
                    if ($allowOrigin = "*") then () else <set-header name="Access-Control-Allow-Credentials" value="true"/>
                )
            }
            </forward>
        </dispatch>

else if (contains($exist:path, "/images/")) then
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/images/{substring-after($exist:path, '/images/')}"/>
    </dispatch>

else if (matches($exist:resource, "\.(png|jpg|jpeg|gif|tif|tiff|txt|mei)$", "s")) then
    let $path := 
        if (starts-with($exist:path, "/collection/")) then
            substring-after($exist:path, "/collection/")
        else
            $exist:path
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/data/{$path}"/>
        </dispatch>

else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/lib/api.xql">
            <set-header name="Access-Control-Allow-Origin" value="{$allowOrigin}"/>
            { if ($allowOrigin = "*") then () else <set-header name="Access-Control-Allow-Credentials" value="true"/> }
            <set-header name="Access-Control-Allow-Methods" value="GET, POST, DELETE, PUT, PATCH, OPTIONS"/>
            <set-header name="Access-Control-Allow-Headers" value="Content-Type, api_key, Authorization"/>
            <set-header name="Access-Control-Expose-Headers" value="pb-start, pb-total"/>
            <set-header name="Cache-Control" value="no-cache"/>
        </forward>
    </dispatch>