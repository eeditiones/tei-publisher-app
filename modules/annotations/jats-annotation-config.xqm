xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations/config/jats";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare namespace xlink="http://www.w3.org/1999/xlink";

(:~
 : Name of the attribute to use as reference key for entities
 :)
declare variable $anno:reference-key := 'specific-use';

(:~
 : Return the entity reference key for the given node.
 :)
declare function anno:get-key($node as element()) as xs:string? {
    $node/@*[local-name(.) = $anno:reference-key]
};

(:~
 : Determine the entity type of the given node and return as string.
 :)
declare function anno:entity-type($node as element()) as xs:string? {
    typeswitch($node)
        case element(named-content) return
            let $content-type := $node/@content-type/string()
            return
                switch($content-type)
                    case "person" return "person"
                    case "place" return "place"
                    case "organization" return "organization"
                    case "term" return "term"
                    case "work" return "work"
                    default return ()
        case element(name) return
            (: name elements in contrib context are persons :)
            if ($node/ancestor::contrib) then
                "person"
            else
                ()
        case element(contrib) return
            (: contrib elements with contrib-type="person" are persons :)
            if ($node/@contrib-type = "person") then
                "person"
            else
                ()
        default return
            ()
};

(:~
 : Create JATS for the given type, properties and content of an annotation and return it.
 : This function is called when annotations are merged into the original JATS.
 :)
declare function anno:annotations($type as xs:string, $properties as map(*)?, $content as function(*)) {
    switch ($type)
        case "person" return
            <named-content content-type="person" specific-use="{$properties?specific-use}">{$content()}</named-content>
        case "place" return
            <named-content content-type="place" specific-use="{$properties?specific-use}">{$content()}</named-content>
        case "term" return
            <named-content content-type="term" specific-use="{$properties?specific-use}">{$content()}</named-content>
        case "organization" return
            <named-content content-type="organization" specific-use="{$properties?specific-use}">{$content()}</named-content>
        case "work" return
            <named-content content-type="work" specific-use="{$properties?specific-use}">{$content()}</named-content>
        case "hi" return
            switch ($properties?rend)
                case "b" case "bold" return
                    <bold>{$content()}</bold>
                case "i" case "italic" return
                    <italic>{$content()}</italic>
                case "u" case "underline" return
                    <underline>{$content()}</underline>
                case "s" case "strike" return
                    <strike>{$content()}</strike>
                default return
                    <styled-content>
                    { 
                        if ($properties?style-type) then attribute style-type { $properties?style-type } else (),
                        if ($properties?style) then attribute style { $properties?style } else (),
                        $content()
                    }
                    </styled-content>
        case "abbreviation" return
            <abbrev>
            {
                if ($properties?expan) then attribute alt { $properties?expan } else (),
                $content()
            }
            </abbrev>
        case "note" return 
            let $parsed := parse-xml-fragment($properties?content) => anno:fix-namespaces()
            let $id := util:uuid()
            return (
                $content(),
                <xref ref-type="fn" rid="{$id}"/>,
                <fn id="{$id}">{$parsed}</fn>
            )
        case "date" return
            (: JATS doesn't have a general date element, use named-content with date info :)
            <named-content content-type="date">
            {
                if ($properties?when) then attribute iso-8601-date { $properties?when } else (),
                if ($properties?from) then attribute date-type { "from" } else (),
                if ($properties?to) then attribute date-type { "to" } else (),
                $content()
            }
            </named-content>
        case "ref" return
            <ext-link ext-link-type="uri" xlink:href="{$properties?('xlink:href')}">{$content()}</ext-link>
        case "pb" return
            (: JATS uses milestone-start for page breaks :)
            <milestone-start content-type="page" n="{$properties?n}">
            {
                if ($properties?facs != "") then
                    attribute facs { $properties?facs}
                else
                    ()
            }
            </milestone-start>
        case "edit" return
            $properties?content
        default return
            $content()
};

(:~
 : Search for existing occurrences of annotations of the given type and key
 : in the data collection.
 :
 : Used to display the occurrence count next to authority entries.
 :)
declare function anno:occurrences($type as xs:string, $key as xs:string) {
    switch ($type)
        case "person" return
            collection($config:data-default)//named-content[@content-type = "person"][@specific-use = $key]
        case "place" return
            collection($config:data-default)//named-content[@content-type = "place"][@specific-use = $key]
        case "term" return
            collection($config:data-default)//named-content[@content-type = "term"][@specific-use = $key]
        case "organization" return
            collection($config:data-default)//named-content[@content-type = "organization"][@specific-use = $key]
        case "work" return
            collection($config:data-default)//named-content[@content-type = "work"][@specific-use = $key]
        default return ()
};

(:~
 : Extend the document header with revision information and process annotations.
 : For JATS, this is a no-op since JATS doesn't have the same header structure as TEI.
 :)
declare function anno:extend-header($nodes as node()*, $log as map(*)?) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    anno:extend-header($node/node(), $log)
                }
            case element(article) return
                element { node-name($node) } {
                    $node/@*,
                    anno:extend-header($node/node(), $log),
                    if (not($node/back)) then
                        <back>
                            <fn-group content-type="footnotes">
                                {
                                    root($node)//body//fn[@id]
                                }
                            </fn-group>
                        </back>
                    else
                        ()
                }
            case element(back) return
                element { node-name($node) } {
                    $node/@*,
                    anno:extend-header($node/node(), $log),
                    if (not($node/fn-group)) then
                        <fn-group content-type="footnotes">
                            {
                                root($node)//body//fn[@id]
                            }
                        </fn-group>
                    else
                        ()
                }
            case element(fn-group) return
                element { node-name($node) } {
                    $node/@*,
                    anno:extend-header($node/node(), $log),
                    $node//fn[@id],
                    root($node)//body//fn[@id]
                }
            case element(fn) return
                if ($node/@id) then
                    ()
                else
                    $node
            case element(article-meta) return
                element { node-name($node) } {
                    $node/@*,
                    if (not($node/pub-history)) then
                        if ($log?message != "") then
                            <pub-history>
                                <event event-type="{$log?status}">
                                    <event-desc>{$log?message}</event-desc>
                                    <date iso-8601-date="{current-dateTime()}"/>
                                </event>
                            </pub-history>
                        else
                            ()
                    else
                        (),
                    anno:extend-header($node/node(), $log)
                }
            case element(pub-history) return
                element { node-name($node) } {
                    $node/@*,
                    $node/node(),
                    if ($log?message != "") then
                        <event event-type="{$log?status}">
                            <event-desc>{$log?message}</event-desc>
                            <date iso-8601-date="{current-dateTime()}"/>
                        </event>
                    else
                        ()
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    anno:extend-header($node/node(), $log)
                }
            default return
                $node
};

declare %private function anno:fix-namespaces($nodes as item()*) {
    (: JATS doesn't use namespaces, so just return nodes as-is :)
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                anno:fix-namespaces($node/node())
            case element() return
                (: Remove any namespace declarations and return element in default namespace :)
                element { local-name($node) } {
                    $node/@*, for $child in $node/node() return anno:fix-namespaces($child)
                }
            default return
                $node
};

