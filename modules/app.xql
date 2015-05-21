xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "../content/util.xql";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

declare variable $app:ext-html := 
    map {
        "uri": "http://www.tei-c.org/tei-simple/xquery/ext-html",
        "prefix": "ext",
        "at": "../modules/ext-html.xql"
    };
    
declare variable $app:ext-latex := 
    map {
        "uri": "http://www.tei-c.org/tei-simple/xquery/ext-latex",
        "prefix": "ext-latex",
        "at": "../modules/ext-latex.xql"
    };

declare variable $app:ext-fo := 
    map {
        "uri": "http://www.tei-c.org/tei-simple/xquery/ext-fo",
        "prefix": "ext-fo",
        "at": "../modules/ext-fo.xql"
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
    %templates:default("odd", "teisimple.odd")
function app:doc-table($node as node(), $model as map(*), $odd as xs:string) {
    let $docs :=
        dbutil:find-by-mimetype(xs:anyURI($config:data-root), "application/xml", function($resource) {
            let $name := replace($resource, "^.*/([^/]+)$", "$1")
            return
                <tr>
                    <td><a href="test/{$name}?odd={$odd}">{$name}</a></td>
                    <td>
                        {
                            templates:process(
                                <div class="btn-group" role="group">
                                    <a class="btn btn-default" 
                                        href="modules/fo.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                        <i class="glyphicon glyphicon-print"/> PDF</a>
                                    <a class="btn btn-default" 
                                        href="modules/latex.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
                                        <i class="glyphicon glyphicon-print"/> LaTeX</a>
                                    <a class="btn btn-default" 
                                        href="modules/get-epub.xql?odd={$odd}&amp;doc={substring-after($resource, $config:app-root || '/')}">
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
    for $doc in $docs
    order by $doc/td/a/text()
    return
        $doc
};

declare
    %templates:wrap
    %templates:default("odd", "teisimple.odd")
function app:odd-table($node as node(), $model as map(*), $odd as xs:string) {
    dbutil:find-by-mimetype(xs:anyURI($config:odd-root), "application/xml", function($resource) {
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
                                    <i class="glyphicon glyphicon-ok"/> Use ODD
                                </a>
                                <a class="btn btn-default"
                                    href="?action=refresh&amp;source={$name}.odd&amp;odd={$odd}">
                                    <i class="glyphicon glyphicon-refresh"/> Regenerate</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($resource, $config:app-root)}">
                                    <i class="glyphicon glyphicon-edit"/> ODD</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}-web.xql">
                                    { if ($xqlWebAvail) then () else attribute disabled { "disabled" } }
                                    <i class="glyphicon glyphicon-edit"/> Web XQL</a>
                                <a class="btn btn-default" data-template="app:load-source"
                                    href="{substring-after($config:output-root, $config:app-root)}/{$name}-print.xql">
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
    %templates:default("view", "div")
function app:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?, $view as xs:string) {
    map {
        "data": app:load-xml($view, $root, $doc)
    }
};

declare function app:load-xml($view as xs:string, $root as xs:string?, $doc as xs:string) {
	if ($view = "div") then
        if ($root) then
            let $doc := doc($config:app-root || "/" || $doc)
            return 
                util:node-by-id($doc, $root)
        else
            (doc($config:app-root || "/" || $doc)//tei:div)[1]
    else
        doc($config:app-root || "/" || $doc)/tei:TEI/tei:text
};

declare function app:back-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        attribute href {
            "../index.html?odd=" || $odd
        },
        $node/@*,
        $node/node()
    }
};

declare function app:pdf-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        attribute href {
            "../modules/fo.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root)
        },
        $node/@*,
        $node/node()
    }
};

declare function app:latex-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        attribute href {
            "../modules/latex.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root)
        },
        $node/@*,
        $node/node()
    }
};

declare function app:epub-link($node as node(), $model as map(*), $odd as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "../modules/get-epub.xql?odd=" || $odd || "&amp;doc=" || substring-after(document-uri(root($model?data)), $config:app-root) },
        $node/node()
    }
};

declare 
    %templates:default("view", "div")
function app:single-page-link($node as node(), $model as map(*), $odd as xs:string, $view as xs:string) {
    let $type := if ($view = "single") then "div" else "single"
    let $class := if ($view = "single") then $node/@class || " active" else $node/@class
    return
        element { node-name($node) } {
            $node/@* except ($node/@href, $node/@class),
            attribute class { $class },
            attribute href { "?odd=" || $odd || "&amp;view=" || $type },
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

declare 
    %templates:default("view", "div")
function app:view($node as node(), $model as map(*), $odd as xs:string, $view as xs:string) {
    let $xml := 
        if ($view = "div") then
            app:get-content($model("data"))
        else
            $model?data//*:body/*
    return
        app:process-content($odd, $xml)
};

declare function app:process-content($odd as xs:string, $xml as element()*) {
	let $html :=
        pmu:process($config:odd-root || "/" || $odd, $xml, $config:output-root, "web", "../generated", $app:ext-html)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    return
        <div class="content {$class}">
        {$html}
        </div>
};

declare
    %templates:wrap
function app:table-of-contents($node as node(), $model as map(*), $odd as xs:string) {
    app:toc-div(root($model?data), $odd)
};

declare %private function app:toc-div($node, $odd as xs:string) {
    let $divs := $node//tei:div[empty(ancestor::tei:div) or ancestor::tei:div[1] is $node][tei:head]
    return
        <ul>
        {
            for $div in $divs
            let $html := $div/tei:head//text()
            return
                <li>
                    <a class="toc-link" href="{util:document-name($div)}?root={util:node-id($div)}&amp;odd={$odd}">{$html}</a>
                    {app:toc-div($div, $odd)}
                </li>
        }
        </ul>
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

declare 
    %templates:wrap
    %templates:default("view", "div")
function app:navigation($node as node(), $model as map(*), $view as xs:string) {
    let $div := $model("data")
    let $work := $div/ancestor-or-self::tei:TEI
    return
        if ($view = "single") then
            map {
                "div" : $div,
                "work" : $work
            }
        else
            let $parent := $div/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
            let $prevDiv := $div/preceding::tei:div[1]
            let $prevDiv := app:get-previous(if ($parent and (empty($prevDiv) or $div/.. >> $prevDiv)) then $div/.. else $prevDiv)
            let $nextDiv := app:get-next($div)
        (:        ($div//tei:div[not(*[1] instance of element(tei:div))] | $div/following::tei:div)[1]:)
            return
                map {
                    "previous" : $prevDiv,
                    "next" : $nextDiv,
                    "work" : $work,
                    "div" : $div
                }
};

declare function app:get-next($div as element()) {
    if ($div/tei:div) then
        if (count(($div/tei:div[1])/preceding-sibling::*) < 5) then
            app:get-next($div/tei:div[1])
        else
            $div/tei:div[1]
    else
        $div/following::tei:div[1]
};

declare function app:get-previous($div as element(tei:div)?) {
    if (empty($div)) then
        ()
    else
        if (
            empty($div/preceding-sibling::tei:div)  (: first div in section :)
            and count($div/preceding-sibling::*) < 5 (: less than 5 elements before div :)
            and $div/.. instance of element(tei:div) (: parent is a div :)
        ) then
            app:get-previous($div/..)
        else
            $div
};

declare function app:get-content($div as element()) {
    if ($div instance of element(tei:teiHeader)) then 
        $div
    else
        if ($div instance of element(tei:div)) then
            if ($div/tei:div) then
                if (count(($div/tei:div[1])/preceding-sibling::*) < 5) then
                    let $child := $div/tei:div[1]
                    return
                        element { node-name($div) } {
                            $div/@*,
                            $child/preceding-sibling::*,
                            app:get-content($child)
                        }
                else
                    element { node-name($div) } {
                        $div/@*,
                        $div/tei:div[1]/preceding-sibling::*
                    }
            else
                $div
        else ()
};

declare
    %templates:wrap
function app:navigation-title($node as node(), $model as map(*)) {
    app:work-title($model('data')/ancestor-or-self::tei:TEI)
};

declare
    %templates:default("view", "div")
function app:navigation-link($node as node(), $model as map(*), $direction as xs:string, $odd as xs:string, $view as xs:string) {
    if ($view = "single") then
        ()
    else if ($model($direction)) then
        <a data-doc="{util:document-name($model($direction))}"
            data-root="{util:node-id($model($direction))}"
            data-current="{util:node-id($model('div'))}"
            data-odd="{$odd}">
        {
            $node/@* except $node/@href,
            let $id := util:document-name($model($direction)) || "?root=" || util:node-id($model($direction)) || "&amp;odd=" || $odd
            return
                attribute href { $id },
            $node/node()
        }
        </a>
    else
        <a href="#" style="visibility: hidden;">{$node/@class, $node/node()}</a>
};

declare %private function app:work-title($work as element(tei:TEI)?) {
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()
    let $main-title := if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
    return
        $main-title
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
                        doc($config:odd-root || "/" || $source),
                        $config:output-root,
                        $module,
                        "../generated",
                        if ($module = "latex") then $app:ext-latex else if ($module = "print") then $app:ext-fo else $app:ext-html)?("module")
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