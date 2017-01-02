xquery version "3.1";

module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

declare variable $app:EXIDE :=
    let $path := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    return
        if ($path) then
            substring-after(util:collection-name($path), repo:get-root())
        else
            ();

declare
    %templates:wrap
function app:odd-table($node as node(), $model as map(*), $odd as xs:string?) {
    let $odd := ($odd, $config:odd)[1]
    let $user := request:get-attribute($config:login-domain || ".user")
    return
        dbutil:scan-resources(xs:anyURI($config:odd-root), function($resource) {
            if (ends-with($resource, ".odd")) then
                let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
                return
                    <tr>
                        <td>
                        {
                            if ($odd = $name || ".odd") then
                                <a href="?odd={$name}.odd">
                                    <i class="material-icons">check_box</i>
                                </a>
                            else
                                <a href="?odd={$name}.odd">
                                    <i class="material-icons">check_box_outline_blank</i>
                                </a>
                        }
                        </td>
                        <td>{$name}</td>
                        <td>
                        {
                            let $outputPath := $config:output-root || "/" || $name
                            let $xqlWebAvail := util:binary-doc-available($outputPath || "-web.xql")
                            let $xqlFoAvail := util:binary-doc-available($outputPath || "-print.xql")
                            let $cssAvail := util:binary-doc-available($outputPath || ".css")
                            return
                                if ($user) then
                                    templates:process(
                                        <div class="btn-group" role="group">
                                            <a class="btn btn-default recompile" title="Regenerate"
                                                href="?source={$name}.odd&amp;odd={$odd}">
                                                <i class="material-icons">update</i>
                                                <span class="hidden-xs">Regenerate</span>
                                            </a>
                                            <div class="btn-group">
                                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                                    <i class="material-icons">code</i> <span class="hidden-xs">Source</span> <span class="caret"/>
                                                </button>
                                                <ul class="dropdown-menu" role="menu">
                                                    <li>
                                                        <a data-template="app:load-source"
                                                            href="{substring-after($resource, $config:app-root)}">
                                                            <i class="material-icons">edit</i> ODD</a>
                                                    </li>
                                                    <li>
                                                        <a data-template="app:load-source"
                                                            href="{substring-after($config:output-root, $config:app-root)}/{$name}-web.xql">
                                                            { if ($xqlWebAvail) then () else attribute disabled { "disabled" } }
                                                            <i class="material-icons">edit</i> Web XQL</a>
                                                    </li>
                                                    <li>
                                                        <a data-template="app:load-source"
                                                            href="{substring-after($config:output-root, $config:app-root)}/{$name}-print.xql">
                                                            { if ($xqlFoAvail) then () else attribute disabled { "disabled" } }
                                                            <i class="material-icons">edit</i> FO XQL</a>
                                                    </li>
                                                    <li>
                                                        <a data-template="app:load-source"
                                                            href="{substring-after($config:output-root, $config:app-root)}/{$name}-latex.xql">
                                                            { if ($xqlFoAvail) then () else attribute disabled { "disabled" } }
                                                            <i class="material-icons">edit</i> LaTeX XQL</a>
                                                    </li>
                                                    <li>
                                                        <a data-template="app:load-source"
                                                            href="{substring-after($config:output-root, $config:app-root)}/{$name}.css">
                                                            { if ($cssAvail) then () else attribute disabled { "disabled" } }
                                                            <i class="material-icons">edit</i> CSS</a>
                                                    </li>
                                                </ul>
                                            </div>
                                        </div>,
                                        $model
                                    )
                                else
                                    ()
                        }
                        </td>
                    </tr>
            else
                ()
        })
};

declare
    %templates:wrap
function app:form-odd-select($node as node(), $model as map(*)) {
    dbutil:scan-resources(xs:anyURI($config:odd-root), function($resource) {
        if (ends-with($resource, ".odd")) then
            let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
            return
                <option value="{replace($resource, "^.*/([^/]+)$", "$1")}">{$name}</option>
        else
            ()
    })
};

declare function app:load-source($node as node(), $model as map(*)) as node()* {
    let $href := $node/@href/string()
    let $link :=
        let $path := string-join(
            (request:get-context-path(), request:get-attribute("$exist:prefix"), $app:EXIDE,
            "index.html?open=" || templates:get-app-root($model) || "/" || $href)
            , "/"
        )
        return
            replace($path, "/+", "/")
    return
        element { node-name($node) } {
            attribute href { $link },
            attribute target { "eXide" },
            attribute class { "eXide-open " || $node/@class },
            attribute data-exide-open { templates:get-app-root($model) || "/" || $href },
            $node/@* except ($node/@href, $node/@class),
            $node/node()
        }
};

declare
    %templates:wrap
function app:action($node as node(), $model as map(*), $source as xs:string?, $action as xs:string?, $new-odd as xs:string?) {
    switch ($action)
        case "create-odd" return
            <div class="panel panel-primary" role="alert">
                <div class="panel-heading"><h3 class="panel-title">Generated Files</h3></div>
                <div class="panel-body">
                    <ul class="list-group">
                    {
                        let $template := doc($config:odd-root || "/template.odd.xml")
                        return
                            xmldb:store($config:odd-root, $new-odd || ".odd", document { app:parse-template($template, $new-odd) }, "text/xml")
                    }
                    </ul>
                </div>
            </div>
        default return
            ()
};

declare %private function app:parse-template($nodes as node()*, $odd as xs:string) {
    for $node in $nodes
    return
        typeswitch ($node)
        case document-node() return
            app:parse-template($node/node(), $odd)
        case element(tei:schemaSpec) return
            element { node-name($node) } {
                $node/@*,
                attribute ident { $odd },
                app:parse-template($node/node(), $odd)
            }
        case element() return
            element { node-name($node) } {
                $node/@*,
                app:parse-template($node/node(), $odd)
            }
        default return
            $node
};
