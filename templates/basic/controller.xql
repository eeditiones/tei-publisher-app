xquery version "3.0";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $logout := request:get-parameter("logout", ());
declare variable $login := request:get-parameter("user", ());

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
    </dispatch>

else if (contains($exist:path, "/resources")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}"/>
    </dispatch>

else if (contains($exist:path, "/transform")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/transform/{substring-after($exist:path, '/transform/')}"/>
    </dispatch>

else if (contains($exist:path, "/components")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/components/{substring-after($exist:path, '/components/')}"/>
    </dispatch>

else if (ends-with($exist:resource, ".xql")) then (
    login:set-user($config:login-domain, (), false()),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/{substring-after($exist:path, '/modules/')}"/>
        <cache-control cache="no"/>
    </dispatch>

) else if ($logout or $login) then (
    login:set-user($config:login-domain, (), false()),
    (: redirect successful login attempts to the original page, but prevent redirection to non-local websites:)
    let $referer := request:get-header("Referer")
    let $this-servers-scheme-and-domain := request:get-scheme() || "://" || request:get-server-name()
    return
        if (starts-with($referer, $this-servers-scheme-and-domain)) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{request:get-header("Referer")}"/>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{replace(request:get-uri(), "^(.*)\?", "$1")}"/>
            </dispatch>

) else if (ends-with($exist:resource, ".html")) then (
    login:set-user($config:login-domain, (), false()),
    let $resource :=
        if (contains($exist:path, "/templates/")) then
            "templates/" || $exist:resource
        else
            $exist:resource
    return
        (: the html page is run through view.xql to expand templates :)
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/{$resource}"/>
            <view>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
    		<error-handler>
    			<forward url="{$exist:controller}/error-page.html" method="get"/>
    			<forward url="{$exist:controller}/modules/view.xql"/>
    		</error-handler>
        </dispatch>

) else (
    login:set-user($config:login-domain, (), false()),
    (: let $id := replace(xmldb:decode($exist:resource), "^(.*)\..*$", "$1") :)
    let $id := xmldb:decode($exist:resource)
    let $path := substring-before($exist:path, $exist:resource)
    let $mode := request:get-parameter("mode", ())
    let $html :=
        if ($exist:resource = "") then
            "index.html"
        else if ($exist:resource = "doc-table.html") then
            "templates/doc-table.html"
        else if ($exist:resource = ("search.html", "toc.html")) then
            $exist:resource
        else
            "view.html"
    return
        if (matches($exist:resource, "\.(png|jpg|jpeg|gif|tif|tiff|txt)$", "s")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
               <forward url="{$exist:controller}/data/{$path}{$id}"/>
           </dispatch>
        else if (ends-with($exist:resource, ".epub")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/get-epub.xql">
                    <add-parameter name="id" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if (ends-with($exist:resource, ".tex")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/latex.xql">
                    <add-parameter name="id" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if (ends-with($exist:resource, ".pdf")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/pdf.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if ($mode = "plain") then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/transform.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/{$html}"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                    {
                        if ($exist:resource != "toc.html") then
                            <add-parameter name="doc" value="{$path}{$id}"/>
                        else
                            ()
                    }
                        <set-header name="Cache-Control" value="no-cache"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>

)
