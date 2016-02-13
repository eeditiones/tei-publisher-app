(:
 : Copyright 2015, Wolfgang Meier
 :
 : This software is dual-licensed:
 :
 : 1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
 : http://creativecommons.org/licenses/by-sa/3.0/
 :
 : 2. http://www.opensource.org/licenses/BSD-2-Clause
 :
 : All rights reserved. Redistribution and use in source and binary forms, with or without
 : modification, are permitted provided that the following conditions are met:
 :
 : * Redistributions of source code must retain the above copyright notice, this list of
 : conditions and the following disclaimer.
 : * Redistributions in binary form must reproduce the above copyright
 : notice, this list of conditions and the following disclaimer in the documentation
 : and/or other materials provided with the distribution.
 :
 : This software is provided by the copyright holders and contributors "as is" and any
 : express or implied warranties, including, but not limited to, the implied warranties
 : of merchantability and fitness for a particular purpose are disclaimed. In no event
 : shall the copyright holder or contributors be liable for any direct, indirect,
 : incidental, special, exemplary, or consequential damages (including, but not limited to,
 : procurement of substitute goods or services; loss of use, data, or profits; or business
 : interruption) however caused and on any theory of liability, whether in contract,
 : strict liability, or tort (including negligence or otherwise) arising in any way out
 : of the use of this software, even if advised of the possibility of such damage.
 :)
xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";

import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd" at "../content/odd2odd.xql";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

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
function app:doc-table($node as node(), $model as map(*), $odd as xs:string?) {
    let $odd := ($odd, $config:default-odd)[1]
    let $docs :=
        for $collection in $config:data-root
        return
            dbutil:find-by-mimetype(xs:anyURI($collection), "application/xml", function($resource) {
                let $name := substring-after($resource, $config:app-root || "/")
                return
                    <li>
                        <h5><a href="{$name}?odd={$odd}">{pages:title(doc($resource)/*)}</a></h5>
                        <div>
                        {
                            let $token := util:uuid()
                            return
                                templates:process(
                                    <div class="toolbar btn-group" role="group">
                                        <div class="btn-group">
                                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                                <i class="material-icons">print</i> <span class="hidden-xs">PDF</span> <span class="caret"/>
                                            </button>
                                            <ul class="dropdown-menu" role="menu">
                                                <li>
                                                    <a class="download-link" data-token="{$token}"
                                                        href="modules/fo.xql?token={$token}&amp;odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                                        PDF via FO
                                                    </a>
                                                </li>
                                                <li>
                                                    <a target="_new"
                                                        href="modules/fo.xql?source=yes&amp;odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                                        FO Code
                                                    </a>
                                                </li>
                                                <li>
                                                    <a class="download-link" data-token="{$token}"
                                                        href="modules/latex.xql?token={$token}&amp;odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                                        PDF via LaTeX
                                                    </a>
                                                </li>
                                                <li>
                                                    <a target="_new"
                                                        href="modules/latex.xql?source=yes&amp;odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                                        LaTeX Code
                                                    </a>
                                                </li>
                                            </ul>
                                        </div>
                                        <a class="btn btn-default download-link" data-token="{$token}"
                                            href="modules/get-epub.xql?token={$token}&amp;odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                            <i class="material-icons">book</i> <span class="hidden-xs">ePUB</span></a>
                                        <a class="btn btn-default" data-template="app:load-source"
                                            href="{substring-after($resource, $config:app-root)}">
                                            <i class="material-icons">code</i> <span class="hidden-xs">Source</span></a>
                                    </div>,
                                    $model
                                )
                        }
                        <span>{$name}</span>
                        <div class="clear"/>
                        </div>
                    </li>
            })
    for $doc in $docs
    order by $doc/td[2]/a/text()
    return
        $doc
};

declare
    %templates:wrap
function app:odd-table($node as node(), $model as map(*), $odd as xs:string?) {
    let $odd := ($odd, $config:default-odd)[1]
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
                                templates:process(
                                    <div class="btn-group" role="group">
                                        <a class="btn btn-default" title="Regenerate"
                                            href="?action=refresh&amp;source={$name}.odd&amp;odd={$odd}">
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
                        }
                        </td>
                    </tr>
            else
                ()
        })
};

declare function app:action($node as node(), $model as map(*), $source as xs:string?, $action as xs:string?, $new-odd as xs:string?) {
    switch ($action)
        case "refresh" return
            <div class="panel panel-primary" role="alert">
                <div class="panel-heading"><h3 class="panel-title">Generated Files</h3></div>
                <div class="panel-body">
                    <ul class="list-group">
                    {
                        for $module in ("web", "print", "latex", "epub")
                        for $file in pmu:process-odd(
                            doc(odd:get-compiled($config:odd-root, $source, $config:compiled-odd-root)),
                            $config:output-root,
                            $module,
                            "../" || $config:output,
                            $config:module-config)?("module")
                        return
                            <li class="list-group-item">{$file}</li>
                    }
                    </ul>
                </div>
            </div>
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

declare function app:parse-template($nodes as node()*, $odd as xs:string) {
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
