(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

(:~
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";

declare variable $pages:app-root := request:get-context-path() || substring-after($config:app-root, "/db");

declare variable $pages:EXIDE :=
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");

declare variable $pages:EDIT_ODD_LINK :=
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://existsolutions.com/apps/tei-publisher"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "odd-editor.html"), "/")
    return
        replace($path, "/+", "/");

declare function pages:pb-document($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
    $id as xs:string?, $view as xs:string?) {
    let $odd := ($node/@odd, request:get-parameter("odd", ())) [1]
    let $data := pages:get-document($doc)
    let $config := tpu:parse-pi(root($data), $view, $odd)
    return
        <pb-document path="{$doc}" root-path="{$config:data-root}" view="{$config?view}" odd="{replace($config?odd, '^(.*)\.odd', '$1')}"
            source-view="{$pages:EXIDE}">
            { $node/@id }
        </pb-document>
};

declare function pages:pb-view($node as node(), $model as map(*), $root as xs:string?, $id as xs:string?,
    $action as xs:string?) {
    element { node-name($node) } {
        attribute node-id { $root },
        if ($id) then
            attribute xml-id { '["' || $id || '"]'}
        else
            (),
        if ($action = "search") then
            attribute highlight { "highlight" }
        else
            (),
        $node/@*,
        $node/*
    }
};

(:~~
 : Generate the actual script tag to import pb-components.
 :)
declare function pages:load-components($node as node(), $model as map(*)) {
    switch ($config:webcomponents)
        case "local" return
            <script type="module" src="resources/scripts/{$node/@src}"></script>
        default return
            <script type="module" 
                src="https://unpkg.com/@teipublisher/pb-components@{$config:webcomponents}/dist/{$node/@src}"></script>
};

declare function pages:current-language($node as node(), $model as map(*), $lang as xs:string?) {
    element { node-name($node) } {
        $node/@*,
        attribute selected { $lang },
        $node/*
    }
};

declare
    %templates:wrap
function pages:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
    $id as xs:string?, $view as xs:string?) {
    let $doc := xmldb:decode($doc)
    let $data :=
        if ($id) then
            let $node := doc($config:data-root || "/" || $doc)/id($id)
            let $config := tpu:parse-pi(root($node), $view)
            let $div := nav:get-section-for-node($config, $node)
            return
                map {
                    "config": $config,
                    "data":
                        if (empty($div)) then
                            $node/following-sibling::tei:div[1]
                        else
                            $div
                }
        else
            pages:load-xml($view, $root, $doc)
    let $node :=
        if ($data?data) then
            $data?data
        else
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <teiHeader>
                    <fileDesc>
                        <titleStmt>
                            <title>Not found</title>
                        </titleStmt>
                    </fileDesc>
                </teiHeader>
                <text>
                    <body>
                        <div>
                            <head>Failed to load!</head>
                            <p>Could not load document {$doc}. Maybe it is not valid TEI or not in the TEI namespace?</p>
                        </div>
                    </body>
                </text>
            </TEI>//tei:div
    return
        map {
            "config": $data?config,
            "data": $node
        }
};

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    for $data in pages:get-document($doc)
    return
        pages:load-xml($data, $view, $root, $doc)
};

declare function pages:load-xml($data as node()*, $view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $config :=
        (: parse processing instructions and remember original context :)
        map:merge((tpu:parse-pi(root($data[1]), $view), map { "context": $data }))
    return
        map {
            "config": $config,
            "data":
                switch ($config?view)
            	    case "div" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return
                                nav:get-section-for-node($config, $node)
                        else
                            nav:get-section($config, $data)
                    case "page" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            nav:get-first-page-start($config, $data)
                    case "single" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data
                    default return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data/tei:TEI/tei:text
        }
};

declare function pages:get-document($idOrName as xs:string) {
    if ($config:address-by-id) then
        root(collection($config:data-root)/id($idOrName))
    else if (starts-with($idOrName, '/')) then
        doc(xmldb:encode-uri($idOrName))
    else
        doc(xmldb:encode-uri($config:data-root || "/" || $idOrName))
};

declare function pages:back-link($node as node(), $model as map(*)) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/"
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:single-page-link($node as node(), $model as map(*), $doc as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "?view=plain&amp;odd=" || $config:odd },
        $node/node()
    }
};

declare function pages:edit-odd-link($node as node(), $model as map(*)) {
    <pb-download url="{$pages:EDIT_ODD_LINK}" source="source"
        params="root={$config:odd-root}&amp;output-root={$config:output-root}&amp;output={$config:output}">
        {$node/@*, $node/node()}
    </pb-download>
};


declare function pages:xml-link($node as node(), $model as map(*), $source as xs:string?) {
    let $doc-path :=
        if ($source = "odd") then
            $config:odd-root || "/" || $config:odd
        else if ($source) then
            $config:app-root || "/" || $source
        else if ($model?work) then
            document-uri(root($model?work))
        else if ($model?data) then
            document-uri(root($model?data))
        else
            ()
    let $eXide-link := $pages:EXIDE || "?open=" || $doc-path
    let $rest-link := '/exist/rest' || $doc-path
    return
        element { node-name($node) } {
            $node/@* except ($node/@href, $node/@class),
            if ($pages:EXIDE)
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
    %templates:default("action", "browse")
function pages:view($node as node(), $model as map(*), $action as xs:string) {
    let $view := pages:determine-view($model?config?view, $model?data)
    let $data :=
        if ($action = "search" and exists(session:get-attribute($config:session-prefix || ".query"))) then
            query:expand($model?config, $model?data)
        else
            $model?data
    let $xml :=
        if ($view = ("div", "page", "body")) then
            pages:get-content($model?config, $data[1])
        else
            $model?data//*:body/*
    return
        pages:process-content($xml, $model?data, $model?config)
};

declare function pages:process-content($xml as node()*, $root as node()*, $config as map(*)) {
    pages:process-content($xml, $root, $config, ())
};

declare function pages:process-content($xml as node()*, $root as node()*, $config as map(*), $userParams as map(*)?) {
    let $params := map:merge((
            map {
                "root": $root,
                "view": $config?view
            },
            $userParams))
	let $html := $pm-config:web-transform($xml, $params, $config?odd)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    let $body := pages:clean-footnotes($html)
    return
        <div class="{$config:css-content-class} {$class}">
        {
            $body,
            if ($html//*[@class="footnote"]) then
                nav:output-footnotes($html//*[@class = "footnote"])
            else
                ()
            ,
            $html//paper-tooltip
        }
        </div>
};

declare function pages:clean-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(paper-tooltip) return
		()
            case element() return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        pages:clean-footnotes($node/node())
                    }
            default return
                $node
};

declare
    %templates:wrap
function pages:table-of-contents($node as node(), $model as map(*), $target as xs:string*) {
    let $current :=
        if ($model?config?view = "page") then
            ($model?data/ancestor-or-self::tei:div[1], $model?data/following::tei:div[1])[1]
        else
            $model?data
    return
        pages:toc-div(root($model?data), $model, $current, $target)
};

declare %private function pages:toc-div($node, $model as map(*), $current as element(), $target as xs:string?) {
    let $view := $model?config?view
    let $divs := nav:get-subsections($model?config, $node)
    return
        <ul>
        {
            for $div in $divs
            let $headings := nav:get-section-heading($model?config, $div)
            let $html :=
                if ($headings/*) then
                    $pm-config:web-transform($headings, map { "header": "short", "root": $div }, $model?config?odd)
                else
                    $headings/string()
            let $root := (
                if ($view = "page") then
                    ($div/*[1][self::tei:pb], $div/preceding::tei:pb[1])[1]
                else
                    (),
                $div
            )[1]
            let $id := "T" ||util:uuid()
            let $hasDivs := exists(nav:get-subsections($model?config, $div))
            let $isIn := if ($div/descendant::*[. is $current]) then "in" else ()
            let $isCurrent := if ($div is $current) then "active" else ()
            let $icon := if ($isIn) then "expand_less" else "expand_more"
            return
                <li>
                {
                    if ($hasDivs) then
                        <pb-collapse>
                            <span slot="collapse-trigger">
                                <pb-link node-id="{util:node-id($root)}" emit="{$target}">{$html}</pb-link>
                            </span>
                            <span slot="collapse-content">
                            { pages:toc-div($div, $model, $current, $target) }
                            </span>
                        </pb-collapse>
                    else
                        <pb-link node-id="{util:node-id($root)}" emit="{$target}">{$html}</pb-link>
                }
                </li>
        }
        </ul>
};

declare
    %templates:wrap
function pages:styles($node as node(), $model as map(*)) {
    attribute href {
        let $name := replace($config:odd, "^([^/\.]+).*$", "$1")
        return
            $pages:app-root || "/" || $config:output || "/" || $name || ".css"
    }
};

declare
    %templates:wrap
function pages:navigation($node as node(), $model as map(*), $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $div := $model?data
    let $work := root($div)/*
    let $map := map {
        "div" : $div,
        "work" : $work
    }
    return
        if ($view = "single") then
            $map
        else
            map:merge(($map, map {
                "previous": $config:previous-page($model?config, $div, $view),
                "next": $config:next-page($model?config, $div, $view)
            }))
};

declare function pages:get-content($config as map(*), $div as element()) {
    nav:get-content($config, $div)
};

declare
    %templates:wrap
function pages:navigation-title($node as node(), $model as map(*)) {
    nav:get-document-title($model?config, root($model('data'))/*)
};

declare function pages:navigation-link($node as node(), $model as map(*), $direction as xs:string) {
        if ($model?config?view = "single") then
            ()
        else if ($model($direction)) then
            let $doc :=
                config:get-identifier($model($direction))
            return
                <a data-doc="{$doc}"
                    data-root="{util:node-id($model($direction))}"
                    data-current="{util:node-id($model('div'))}"
                    data-odd="{$config:odd}">
                {
                    $node/@* except $node/@href,
                    let $id := $doc || "?root=" || util:node-id($model($direction))
                        || "&amp;odd=" || $config:odd || "&amp;view=" || $model?config?view
                    return
                        attribute href { $id },
                    $node/node()
                }
                </a>
        else
            let $doc :=
                config:get-identifier($model?data)
            return
                <a href="#" style="visibility: hidden;"
                    data-doc="{$doc}">{$node/@class, $node/node()}</a>
};

declare function pages:pb-page($node as node(), $model as map(*), $template as xs:string?) {
    let $model := map:merge(
        (
            $model,
            map { "app": request:get-context-path() || substring-after($config:app-root, "/db") }
        )
    )
    return
        element { node-name($node) } {
            $node/@*,
            attribute app-root { request:get-context-path() || substring-after($config:app-root, "/db") },
            attribute template { $template },
            templates:process($node/*, $model)
        }
};

declare function pages:determine-view($view as xs:string?, $node as node()) {
    typeswitch ($node)
        case element(tei:body) return
            "body"
        case element(tei:front) return
            "body"
        case element(tei:back) return
            "body"
        default return
            if ($view) then $view else $config:default-view
};

declare function pages:switch-view($node as node(), $model as map(*), $root as xs:string?, $doc as xs:string, $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $targetView := if ($view = "page") then "div" else "page"
    let $root := pages:switch-view-id($model?data, $view)
    return
        element { node-name($node) } {
            $node/@* except $node/@class,
            if (pages:has-pages($model?data)) then (
                attribute href {
                    "?root=" ||
                    (if (empty($root) or $root instance of element(tei:body) or $root instance of element(tei:front)) then () else util:node-id($root)) ||
                    "&amp;odd=" || $model?config?odd || "&amp;view=" || $targetView
                },
                if ($view = "page") then (
                    attribute aria-pressed { "true" },
                    attribute class { $node/@class || " active" }
                ) else
                    $node/@class
            ) else (
                $node/@class,
                attribute disabled { "disabled" }
            ),
            templates:process($node/node(), $model)
        }
};

declare function pages:has-pages($data as element()+) {
    exists(root($data)//tei:pb)
};

declare function pages:switch-view-id($data as element()+, $view as xs:string) {
    let $root :=
        if ($view = "div") then
            ($data/*[1][self::tei:pb], $data/preceding::tei:pb[1])[1]
        else
            ($data/ancestor::tei:div, $data/following::tei:div, $data/ancestor::tei:body, $data/ancestor::tei:front)[1]
    return
        $root
};

declare function pages:parse-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        for $attr in $node/@*
        return
            if (matches($attr, "\$\{[^\}]+\}")) then
                attribute { node-name($attr) } {
                    string-join(
                        let $parsed := analyze-string($attr, "\$\{([^\}]+?)(?::([^\}]+))?\}")
                        for $token in $parsed/node()
                        return
                            typeswitch($token)
                                case element(fn:non-match) return $token/string()
                                case element(fn:match) return
                                    let $paramName := $token/fn:group[1]/string()
                                    let $default := $token/fn:group[2]/string()
                                    let $found := [
                                        request:get-parameter($paramName, $default),
                                        $model($paramName),
                                        session:get-attribute($config:session-prefix || "." || $paramName)
                                    ]
                                    return
                                        array:fold-right($found, (), function($in, $value) {
                                            if (exists($in)) then $in else $value
                                        })
                                default return $token
                    )
                }
            else
                $attr,
        templates:process($node/node(), $model)
    }
};

declare 
    %templates:wrap
function pages:languages($node as node(), $model as map(*)) {
    let $json := json-doc($config:app-root || "/resources/i18n/languages.json")
    return
        map:for-each($json, function($key, $value) {
            <paper-item value="{$key}">{$value}</paper-item>
        })
};