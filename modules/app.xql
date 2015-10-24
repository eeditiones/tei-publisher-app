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
                    <tr>
                        <td><a href="{$name}?odd={$odd}">{$name}</a></td>
                        <td class="hidden-xs"><a href="{$name}?odd={$odd}">{pages:title(doc($resource)/*)}</a></td>
                        <td>
                            {
                                templates:process(
                                    <div class="btn-group" role="group">
                                        <div class="btn-group">
                                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                                <i class="glyphicon glyphicon-print"/> <span class="hidden-xs">PDF</span> <span class="caret"/>
                                            </button>
                                            <ul class="dropdown-menu" role="menu">
                                                <li>
                                                    <a href="modules/fo.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
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
                                                    <a href="modules/latex.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
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
                                        <a class="btn btn-default" 
                                            href="modules/get-epub.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                            <i class="glyphicon glyphicon-book"/> <span class="hidden-xs">ePUB</span></a>
                                        <a class="btn btn-default" data-template="app:load-source"
                                            href="{substring-after($resource, $config:app-root)}">
                                            <i class="glyphicon glyphicon-edit"/> <span class="hidden-xs">View Source</span></a>
                                    </div>,
                                    $model
                                )
                            }
                        </td>
                    </tr>
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
                                        <a class="btn btn-default {if ($odd = $name || '.odd') then 'active' else ''}" href="?odd={$name}.odd">
                                            <i class="glyphicon glyphicon-ok"/> <span class="hidden-xs">Use ODD</span>
                                        </a>
                                        <a class="btn btn-default"
                                            href="?action=refresh&amp;source={$name}.odd&amp;odd={$odd}">
                                            <i class="glyphicon glyphicon-refresh"/> <span class="hidden-xs">Regenerate</span></a>
                                        <div class="btn-group">
                                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                                <i class="glyphicon glyphicon-edit"/> <span class="hidden-xs">Sources</span> <span class="caret"/>
                                            </button>
                                            <ul class="dropdown-menu" role="menu">
                                                <li>
                                                    <a data-template="app:load-source"
                                                        href="{substring-after($resource, $config:app-root)}">
                                                        <i class="glyphicon glyphicon-edit"/> ODD</a>
                                                </li>
                                                <li>
                                                    <a data-template="app:load-source"
                                                        href="{substring-after($config:output-root, $config:app-root)}/{$name}-web.xql">
                                                        { if ($xqlWebAvail) then () else attribute disabled { "disabled" } }
                                                        <i class="glyphicon glyphicon-edit"/> Web XQL</a>
                                                </li>
                                                <li>
                                                    <a data-template="app:load-source"
                                                        href="{substring-after($config:output-root, $config:app-root)}/{$name}-print.xql">
                                                        { if ($xqlFoAvail) then () else attribute disabled { "disabled" } }
                                                        <i class="glyphicon glyphicon-edit"/> FO XQL</a>
                                                </li>
                                                <li>
                                                    <a data-template="app:load-source"
                                                        href="{substring-after($config:output-root, $config:app-root)}/{$name}-latex.xql">
                                                        { if ($xqlFoAvail) then () else attribute disabled { "disabled" } }
                                                        <i class="glyphicon glyphicon-edit"/> LaTeX XQL</a>
                                                </li>
                                                <li>
                                                    <a data-template="app:load-source"
                                                        href="{substring-after($config:output-root, $config:app-root)}/{$name}.css">
                                                        { if ($cssAvail) then () else attribute disabled { "disabled" } }
                                                        <i class="glyphicon glyphicon-edit"/> CSS</a>
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

declare function app:action($node as node(), $model as map(*), $source as xs:string?, $action as xs:string?) {
    switch ($action)
        case "refresh" return
            <div class="alert alert-success" role="alert">
                <p>Generated files:</p>
                <ul>
                {
                    for $module in ("web", "print", "latex", "epub")
                    for $file in pmu:process-odd(
                        doc(odd:get-compiled($config:odd-root, $source, $config:compiled-odd-root)),
                        $config:output-root,
                        $module,
                        "../" || $config:output,
                        $config:module-config)?("module")
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