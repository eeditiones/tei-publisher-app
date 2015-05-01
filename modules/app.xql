xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

declare variable $app:ext-html := 
    map {
        "uri": "http://www.tei-c.org/tei-simple/xquery/ext-html",
        "prefix": "ext",
        "at": "../modules/ext-html.xql"
    };

declare variable $app:EXIDE := 
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");
        
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
                                <a class="btn btn-default" 
                                    href="modules/fo.xql?odd=teisimple.odd&amp;doc={substring-after($resource, $config:data-root || '/')}">
                                    <i class="glyphicon glyphicon-print"/> PDF</a>
                                <a class="btn btn-default" 
                                    href="modules/get-epub.xql?odd=teisimple.odd&amp;doc={substring-after($resource, $config:data-root || '/')}">
                                    <i class="glyphicon glyphicon-book"/> ePUB</a>
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
                    let $xqlWebAvail := util:binary-doc-available($outputPath || "-web.xql")
                    let $xqlFoAvail := util:binary-doc-available($outputPath || "-fo.xql")
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
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}-web.xql">
                                    { if ($xqlWebAvail) then () else attribute disabled { "disabled" } }
                                    <i class="glyphicon glyphicon-edit"/> Web XQL</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}-fo.xql">
                                    { if ($xqlFoAvail) then () else attribute disabled { "disabled" } }
                                    <i class="glyphicon glyphicon-edit"/> Print XQL</a>
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
function app:load($node as node(), $model as map(*), $doc as xs:string) {
    let $xml := doc($config:app-root || "/" || $doc)//tei:text
    return
        map {
            "data": $xml
        }
};

declare function app:pdf-link($node as node(), $model as map(*), $doc as xs:string) {
    element { node-name($node) } {
        attribute href {
            "../modules/fo.xql?odd=teisimple.odd&amp;doc=" || util:document-name($model?data)
        },
        $node/@*,
        $node/node()
    }
};

declare function app:epub-link($node as node(), $model as map(*), $doc as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "../modules/get-epub.xql?odd=teisimple.odd&amp;doc=" || util:document-name($model?data) },
        $node/node()
    }
};

declare function app:xml-link($node as node(), $model as map(*), $doc as xs:string) {
    let $doc-path := $config:app-root || $doc
    let $eXide-link := $app:EXIDE || "?open=" || $doc-path
    let $rest-link := '/exist/rest' || $doc-path
    return
        element { node-name($node) } {
            $node/@* except ($node/@href, $node/@class),
            if ($app:EXIDE)
            then (
                attribute href { $eXide-link },
                attribute data-exide-open { $doc-path },
                attribute class { "eXide-open " || $node/@class },
                attribute target { "eXide" }
            ) else (
                attribute href { $rest-link },
                attribute target { "_blank" }
            ),
            $node/node()
        }
};

declare function app:view($node as node(), $model as map(*), $odd as xs:string) {
    let $xml := $model("data")
    let $html :=
        pmu:process($config:odd-root || "/" || $odd, $xml, $config:output-root, "web", "../generated", $app:ext-html)
    let $class := if ($html//*[@class = "margin-note"]) then "margin-right" else ()
    return
        <div class="content {$class}">
        {$html}
        </div>
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
                        "web",
                        "../generated",
                        $app:ext-html)?("module", "style")
                    return
                        <li>{$file}</li>,
                    for $file in pmu:process-odd(
                        doc($config:odd-root || "/" || $odd), 
                        $config:output-root,
                        "print",
                        "../generated",
                        $app:ext-html)("module")
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