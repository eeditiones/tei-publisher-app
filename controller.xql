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

(: static HTML page for API documentation should be served directly to make sure it is always accessible :)
else if ($exist:path eq '/api.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/api.html"/>
    </dispatch>

(: static resources from the resources, transform, templates, odd or modules subirectories are directly returned :)
else if (matches($exist:path, "^.*/(resources|transform|templates)/.*$")
    or matches($exist:path, "^.*/odd/.*\.css$")
    or matches($exist:path, "^.*/modules/.*\.json$")) then
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
                    <set-header name="Cache-Control" value="max-age=31536000"/>,
                    <set-header name="Access-Control-Allow-Origin" value="{$allowOrigin}"/>,
                    if ($allowOrigin = "*") then () else <set-header name="Access-Control-Allow-Credentials" value="true"/>
                )
            }
            </forward>
        </dispatch>

(: other images are resolved against the data collection and also returned directly :)
else if (matches($exist:resource, "\.(png|jpg|jpeg|gif|tif|tiff|txt|mei)$", "s")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/data/{$exist:path}">
            <set-header name="Cache-Control" value="max-age=31536000"/>
        </forward>
    </dispatch>

(: all other requests are passed on the Open API router :)
else
    let $main := 
        if (matches($exist:path, "^/+api/+(?:odd|lint)")) then 
            "api-odd.xql" 
        else if (matches($exist:path, "/+tex$") or matches($exist:path, "/+api/+apps/+generate$")) then
            "api-dba.xql"
        else 
            "api.xql"
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/lib/{$main}">
                <set-header name="Access-Control-Allow-Origin" value="{$allowOrigin}"/>
                { if ($allowOrigin = "*") then () else <set-header name="Access-Control-Allow-Credentials" value="true"/> }
                <set-header name="Access-Control-Allow-Methods" value="GET, POST, DELETE, PUT, PATCH, OPTIONS"/>
                <set-header name="Access-Control-Allow-Headers" value="Content-Type, api_key, Authorization"/>
                <set-header name="Access-Control-Expose-Headers" value="pb-start, pb-total"/>
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
        </dispatch>