xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace annocfg = "http://teipublisher.com/api/annotations/config" at "../../annotation-config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace rapi="http://teipublisher.com/api/registers" at "../../registers.xql";

declare function anno:find-references($request as map(*)) {
    map:merge(
        for $id in $request?parameters?id
        let $matches := annocfg:occurrences($request?parameters?register, $id)
        where count($matches) > 0
        return
            map:entry($id, count($matches))
    )
};

(:~
 : Merge and optionally save the annotations passed in the request body.
 :)
declare function anno:save($request as map(*)) {
    let $body := $request?body
    let $annotations := $body?annotations
    return
        if ($annotations instance of array(*)) then
            let $path := xmldb:decode($request?parameters?path)
            let $srcDoc := config:get-document($path)
            return
                anno:merge-and-save($srcDoc, $path, $annotations, $body?log)
        else
            let $result :=
                for $path in map:keys($annotations)
                let $srcDoc := config:get-document($path)
                return
                    anno:merge-and-save($srcDoc, $path, $annotations($path), $body?log)
            return
                router:response(200, count(map:keys($annotations)) || ' documents merged')

};

declare function anno:merge-and-save($srcDoc as node(), $path as xs:string, $annotations as array(*),
    $log as map(*)?) {
    let $hasAccess := sm:has-access(document-uri(root($srcDoc)), "rw-")
    return
        if (not($hasAccess) and request:get-method() = 'PUT') then
            error($errors:FORBIDDEN, "Not allowed to write to " || $path)
        else if ($srcDoc) then
            let $doc := util:expand($srcDoc/*, 'add-exist-id=all')
            let $map := map:merge(
                for $annoGroup in $annotations?*
                group by $id := $annoGroup?context
                let $node := $doc//*[@exist:id = $id]
                where exists($node)
                let $ordered :=
                    for $anno in $annoGroup
                    order by anno:order($anno?type) ascending
                    return $anno
                return
                    map:entry($id, anno:apply($node, $ordered))
            )
            let $merged := anno:merge($doc, $map) => anno:strip-exist-id() => anno:revision($log)
            let $output := document {
                $srcDoc/(processing-instruction()|comment()),
                $merged
            }
            let $serialized := serialize($output, map { "indent": false() })
            let $stored :=
                if (request:get-method() = 'PUT') then
                    xmldb:store(util:collection-name($srcDoc), util:document-name($srcDoc), $serialized)
                else
                    ()
            return
                map {
                    "content": $serialized,
                    "changes": array { $map?* ! anno:strip-exist-id(.) }
                }
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};

(:~
 : Sort annotations: "edit" actions should be process last, "delete" first
 :)
declare function anno:order($type as xs:string) {
    switch ($type)
        case "edit" return 2
        case "delete" return 0
        default return 1
};

declare %private function anno:strip-exist-id($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    anno:strip-exist-id($node/node())
                }
            case element(exist:delete) return
                anno:strip-exist-id($node/node())
            case element() return
                element { node-name($node) } {
                    $node/@* except $node/@exist:*,
                    anno:strip-exist-id($node/node())
                }
            default return
                $node
};

declare function anno:revision($nodes as node()*, $log as map(*)?) {
    if (exists($log) and map:contains($log, "message") and $log?message != '') then
        anno:add-revision($nodes, $log)
    else
        $nodes
};

declare %private function anno:add-revision($nodes as node()*, $log as map(*)?) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    anno:add-revision($node/node(), $log)
                }
            case element(tei:teiHeader) return
                if (not($node/tei:revisionDesc)) then
                    element { node-name($node) } {
                        $node/@*,
                        $node/node(),
                        if ($log?message != "") then
                            <revisionDesc xmlns="http://www.tei-c.org/ns/1.0">
                                <listChange>
                                    <change when="{current-dateTime()}" who="{$log?user}" status="{$log?status}">{$log?message}</change>
                                </listChange>
                            </revisionDesc>
                        else
                            ()
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:add-revision($node/node(), $log)
                    }
            case element(tei:revisionDesc) return
                if (not($node/tei:listChange)) then
                    element { node-name($node) } {
                        $node/@*,
                        $node/node(),
                        if ($log?message != "") then
                            <listChange xmlns="http://www.tei-c.org/ns/1.0">
                                <change when="{current-dateTime()}" who="{$log?user}" status="{$log?status}">{$log?message}</change>
                            </listChange>
                        else
                            ()
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:add-revision($node/node(), $log)
                    }
            case element(tei:listChange) return
                element { node-name($node) } {
                    $node/@*,
                    $node/node(),
                    if ($log?message != "") then
                        <change xmlns="http://www.tei-c.org/ns/1.0" when="{current-dateTime()}" who="{$log?user}" status="{$log?status}">{$log?message}</change>
                    else
                        ()
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    anno:add-revision($node/node(), $log)
                }
            default return
                $node
};

declare %private function anno:merge($nodes as node()*, $elements as map(*)) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document { anno:merge($node/node(), $elements) }
            case element() return
                let $replacement := if ($node/@exist:id) then $elements($node/@exist:id) else ()
                return
                    if ($replacement) then
                        if ($node instance of element(exist:delete)) then
                            anno:merge($replacement/node(), $elements)
                        else
                            element { node-name($replacement) } {
                                $replacement/@*,
                                anno:merge($replacement/node(), $elements)
                            }
                    else
                        element { node-name($node) } {
                            $node/@*,
                            anno:merge($node/node(), $elements)
                        }
            default return
                $node
};

declare %private function anno:apply($node, $annotations) {
    if (empty($annotations)) then
        $node
    else
        let $anno := head($annotations)
        return
            if ($anno?type = "modify") then
                let $target := root($node)//*[@exist:id=$anno?node]
                (: let $target := util:node-by-id(root($node), $anno?node) :)
                let $output := anno:modify($node, $target, $anno)
                return
                    anno:apply($output, tail($annotations))
            else if ($anno?type = "delete") then
                let $target := $node//*[@exist:id=$anno?node]
                (: let $target := util:node-by-id(root($node), $anno?node) :)
                let $output := anno:delete($node, $target)
                return
                    anno:apply($output, tail($annotations))
            else
                let $output := anno:apply($node, $anno?start + 1, $anno?end + 1, $anno)
                return
                    anno:apply($output, tail($annotations))
};

declare %private function anno:delete($nodes as node()*, $target as node()) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(tei:lem) return
                if ($target is $node/..) then
                    element exist:delete {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
            case element(tei:rdg) return
                if ($target is $node/..) then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
            case element(tei:sic) | element(tei:abbr) | element(tei:orig) return
                if ($target instance of element(tei:choice) and $target is $node/..) then
                    element exist:delete {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
                else if ($node is $target) then
                    element exist:delete {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
            case element(tei:corr) | element(tei:expan) | element(tei:reg) return
                if ($target instance of element(tei:choice) and $target is $node/..) then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
            case element() return
                if ($node is $target) then
                    element exist:delete {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:delete($node/node(), $target)
                    }
            default return
                $node
};

declare %private function anno:modify($nodes as node()*, $target as node(), $annotation as map(*)) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(tei:choice) | element(tei:app) return
                element { node-name($node) } {
                    $node/@*,
                    anno:modify($node/node(), $target, $annotation)
                }
            case element(tei:rdg) return
                if ($node/.. is $target) then
                    let $pos := count($node/preceding-sibling::tei:rdg) + 1
                    return
                        element { node-name($node) } {
                            $node/@* except $node/@wit,
                            attribute wit { $annotation?properties("wit[" || $pos || "]") },
                            text { $annotation?properties("rdg[" || $pos || "]") }
                        }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:modify($node/node(), $target, $annotation)
                    }
            case element(tei:expan) | element(tei:corr) | element(tei:reg) return
                if ($node/.. is $target) then
                    element { node-name($node) } {
                        $node/@*,
                        text { $annotation?properties(local-name($node)) }
                    }
                else if ($node is $target) then
                    element { node-name($node) } {
                        map:for-each($annotation?properties, function($key, $value) {
                            if ($value != '') then
                                attribute { $key } { $value }
                            else
                                ()
                        }),
                        anno:modify($node/node(), $target, $annotation)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:modify($node/node(), $target, $annotation)
                    }
            case element() return
                if ($node is $target) then
                    element { node-name($node) } {
                        map:for-each($annotation?properties, function($key, $value) {
                            if ($value != '') then
                                attribute { $key } { $value }
                            else
                                ()
                        }),
                        anno:modify($node/node(), $target, $annotation)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        anno:modify($node/node(), $target, $annotation)
                    }
            default return
                $node
};

declare %private function anno:apply($node as node(), $startOffset as xs:int, $endOffset as xs:int, $annotation as map(*)) {
    let $start := anno:find-offset($node, $startOffset, "start", $node instance of element(tei:note))
    let $end := anno:find-offset($node, $endOffset, "end", $node instance of element(tei:note))
    let $startAdjusted :=
        if ($start?2 = 1 and not($start?1 is $end?1)) then
            [anno:find-outermost($node, $start?1, "start"), 1]
        else
            $start
    let $endAdjusted :=
        if ($end?2 = string-length($end?1) and not($start?1 is $end?1)) then
            let $outer := anno:find-outermost($node, $end?1, "end")
            let $offset := if ($outer/following-sibling::node()) then 1 else $end?2
            return
                [anno:find-outermost($node, $end?1, "end"), $offset]
        else
            $end
    return
        anno:transform($node, $startAdjusted, $endAdjusted, false(), $annotation)
};

declare %private function anno:find-outermost($context as node(), $node as node(), $pos as xs:string) {
    let $parent := $node/..
    return
        if ($parent is $context) then
            $node
        else if (
            ($pos = "start" and empty($parent/preceding-sibling::node()))
            or ($pos = "end" and empty($parent/following-sibling::node()))
        ) then
            anno:find-outermost($context, $parent, $pos)
        else
            $parent
};

declare %private function anno:find-offset($nodes as node()*, $offset as xs:int, $pos as xs:string, $isNote as xs:boolean?) {
    if (empty($nodes)) then
        ()
    else
        let $node := head($nodes)
        return
            typeswitch($node)
                case element(tei:choice) return
                    let $primary := $node/tei:sic | $node/tei:abbr | $node/tei:orig
                    let $found := anno:find-offset($primary, $offset, $pos, ())
                    return
                        if (exists($found)) then
                            $found
                        else
                            anno:find-offset(tail($nodes), $offset - anno:string-length($primary), $pos, ())
                case element(tei:app) return
                    let $primary := $node/tei:lem
                    let $found := anno:find-offset($primary, $offset, $pos, ())
                    return
                        if (exists($found)) then
                            $found
                        else
                            anno:find-offset(tail($nodes), $offset - anno:string-length($primary), $pos, ())
                case element(tei:note) return
                    if ($isNote) then
                        let $found := anno:find-offset($node/node(), $offset, $pos, ())
                        return
                            if (exists($found)) then $found else anno:find-offset(tail($nodes), $offset - anno:string-length($node), $pos, ())
                    else
                        anno:find-offset(tail($nodes), $offset, $pos, ())
                case element() return
                    let $found := anno:find-offset($node/node(), $offset, $pos, ())
                    return
                        if (exists($found)) then $found else anno:find-offset(tail($nodes), $offset - anno:string-length($node), $pos, ())
                case text() return
                    let $len := string-length($node)
                    return
                        if ($offset <= $len) then
                            [$node, $offset]
                        (: end is immediately after the node :)
                        else if ($pos = "end" and $offset = $len + 1) then
                            [$node, $len + 1]
                        else
                            anno:find-offset(tail($nodes), $offset - $len, $pos, ())
                default return
                    ()
};

declare %private function anno:string-length($nodes as node()*) {
    anno:string-length($nodes, 0)
};

(:~
 : Compute the string-length of the given node set, taking into account footnotes, choices and app,
 : which should be counted in part only or not at all.
 :)
declare %private function anno:string-length($nodes as node()*, $length as xs:int) {
    if ($nodes) then
        let $node := head($nodes)
        let $newLength :=
            typeswitch ($node)
                case element(tei:note) return
                    $length
                case element(tei:choice) return
                    anno:string-length($node/tei:sic | $node/tei:abbr, $length)
                case element(tei:app) return
                    anno:string-length($node/tei:lem, $length)
                case element() return
                    anno:string-length($node/node(), $length)
                default return
                    $length + string-length($node)
        return
            anno:string-length(tail($nodes), $newLength)
    else
        $length
};

declare %private function anno:transform($nodes as node()*, $start, $end, $inAnno, $annotation as map(*)) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element() return
                (: current element is start node? :)
                if ($node is $start?1) then
                    (: entire element is wrapped :)
                    anno:wrap($annotation, function() {
                        $node,
                        anno:transform($node/following-sibling::node(), $start, $end, true(), $annotation)
                    })
                (: called inside the annotation being processed? :)
                else if ($inAnno) then
                    (: element appears after end: ignore :)
                    if ($node >> $end?1) then
                        ()
                    else if ($node is $end?1) then
                        $node
                    else
                        element { node-name($node) } {
                            $node/@*,
                            anno:transform($node/node(), $start, $end, $inAnno, $annotation)
                        }
                (: outside the annotation :)
                else if ($node << $start?1 or $node >> $end?1) then
                    element { node-name($node) } {
                        $node/@*,
                        anno:transform($node/node(), $start, $end, $inAnno, $annotation)
                    }
                else
                    ()
            case text() return
                if ($node is $start?1) then (
                    text { substring($node, 1, $start?2 - 1) },
                    anno:wrap($annotation, function() {
                        if ($node is $end?1) then
                            substring($node, $start?2, $end?2 - $start?2)
                        else
                            substring($node, $start?2),
                        anno:transform($node/following-sibling::node(), $start, $end, true(), $annotation)
                    }),
                    if ($node is $end?1) then
                        text { substring($node, $end?2) }
                    else
                        ()
                ) else if ($node is $end?1) then
                    if ($inAnno) then
                        text { substring($node, 1, $end?2 - 1) }
                    else
                        text { substring($node, $end?2) }
                else if (($inAnno and $node >> $end?1) or (not($inAnno) and $node >> $start?1 and $node << $end?1)) then
                    ()
                else
                    $node
            default return
                $node
};

declare function anno:wrap($annotation as map(*), $content as function(*)) {
    annocfg:annotations($annotation?type, $annotation?properties, $content)
};