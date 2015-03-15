xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %templates:wrap
function app:doc-table($node as node(), $model as map(*)) {
    dbutil:find-by-mimetype(xs:anyURI($config:data-root), "application/xml", function($resource) {
        let $name := replace($resource, "^.*/([^/]+)$", "$1")
        return
            <tr>
                <td><a href="test/{$name}?odd=teisimple.odd">{$name}</a></td>
                <td>
                    {
                        templates:process(
                            <div class="btn-group" role="group">
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($resource, $config:app-root)}">
                                    <i class="glyphicon glyphicon-edit"/> View Source</a>
                            </div>,
                            $model
                        )
                    }
                </td>
            </tr>
    })
};

declare
    %templates:wrap
function app:odd-table($node as node(), $model as map(*)) {
    dbutil:find-by-mimetype(xs:anyURI($config:odd-root), "application/xml", function($resource) {
        let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
        return
            <tr>
                <td>{$name}</td>
                <td>
                {
                    let $outputPath := $config:output-root || "/" || $name
                    let $xqlAvail := util:binary-doc-available($outputPath || ".xql")
                    let $cssAvail := util:binary-doc-available($outputPath || ".css")
                    return
                        templates:process(
                            <div class="btn-group" role="group">
                                <a class="btn btn-default"
                                    href="?action=refresh&amp;odd={$name}.odd">
                                    <i class="glyphicon glyphicon-refresh"/> Regenerate</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($resource, $config:app-root)}">
                                    <i class="glyphicon glyphicon-edit"/> ODD</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}.xql">
                                    { if ($xqlAvail) then () else attribute disabled { "disabled" } }
                                    <i class="glyphicon glyphicon-edit"/> XQL</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}.css">
                                    { if ($cssAvail) then () else attribute disabled { "disabled" } }
                                    <i class="glyphicon glyphicon-edit"/> CSS</a>
                            </div>,
                            $model
                        )
                }
                </td>
            </tr>
    })
};

declare
    %templates:wrap
function app:view($node as node(), $model as map(*), $odd as xs:string, $doc as xs:string) {
    let $xml := doc($config:data-root || "/" || $doc)//tei:text/*
    return
        pmu:process($config:odd-root || "/" || $odd, $xml, $config:output-root, "../generated")
};

declare
    %templates:wrap
function app:styles($node as node(), $model as map(*), $odd as xs:string) {
    attribute href {
        let $name := replace($odd, "^([^/\.]+).*$", "$1")
        return
            "../" || $config:output || "/" || $name || ".css"
    }
};

declare function app:action($node as node(), $model as map(*), $odd as xs:string?, $action as xs:string?) {
    switch ($action)
        case "refresh" return
            <div class="alert alert-success" role="alert">
                <p>Generated files:</p>
                <ul>
                {
                    for $file in pmu:process-odd(
                        doc($config:odd-root || "/" || $odd), 
                        $config:output-root,
                        "../generated")?("module", "style")
                    return
                        <li>{$file}</li>
                }
                </ul>
            </div>
        default return
            ()
};

declare function app:load-source($node as node(), $model as map(*)) as node()* {
    let $href := $node/@href/string()
    let $link := templates:link-to-app("http://exist-db.org/apps/eXide", "index.html?open=" || templates:get-app-root($model) || "/" || $href)
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