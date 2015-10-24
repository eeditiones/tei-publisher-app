xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $data-collections := $config:setup/collections/path;

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
    
else if (matches($exist:path, "/(" || string-join($data-collections, "|") || ")/.*[^/]+\.xml$")) then
    let $view := request:get-parameter("view", ())
    return
        if ($view = "plain") then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/transform.xql">
                    <set-header name="Cache-Control" value="no-cache"/>
                    <add-parameter name="doc" value="{$exist:path}"/>
                </forward>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/view.html"/>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <set-header name="Cache-Control" value="no-cache"/>
                        <add-parameter name="doc" value="{$exist:path}"/>
                    </forward>
                </view>
        		<error-handler>
        			<forward url="{$exist:controller}/error-page.html" method="get"/>
        			<forward url="{$exist:controller}/modules/view.xql"/>
        		</error-handler>
            </dispatch>
    
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/{$exist:resource}"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>

else if (ends-with($exist:resource, ".xql")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/{$exist:resource}"/>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
    
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>

else if (contains($exist:path, "/templates/")) then
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/{substring-after($exist:path, '/templates/')}"/>
    </dispatch>
    
else if (contains($exist:path, "/resources/")) then
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}"/>
    </dispatch>
    
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
