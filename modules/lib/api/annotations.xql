xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";

declare function anno:save($request as map(*)) {
    let $annotations := $request?body
    let $path := xmldb:decode($request?parameters?path)
    let $srcDoc := config:get-document($path)
    return
        if ($srcDoc) then
            let $doc := util:expand($srcDoc, 'add-exist-id=all')
            let $map := map:merge(
                for $annoGroup in $annotations?*
                group by $id := $annoGroup?context
                let $node := $doc//*[@exist:id = $id]
                where exists($node)
                let $ordered :=
                    for $anno in $annoGroup
                    (: handle deletions first :)
                    order by $anno?type empty least
                    return $anno
                return
                    map:entry($id, anno:apply($node, $ordered))
            )
            let $merged := anno:merge($doc, $map) => anno:strip-exist-id()
            let $stored :=
                if ($request?parameters?store) then
                    xmldb:store(util:collection-name($doc), util:document-name($doc), $merged)
                else
                    ()
            return
                $merged
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};

declare %private function anno:strip-exist-id($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    anno:strip-exist-id($node/node())
                }
            case element() return
                element { node-name($node) } {
                    $node/@* except $node/@exist:*,
                    anno:strip-exist-id($node/node())
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
            case element() return
                if ($node is $target) then
                    anno:delete($node/node(), $target)
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
            case element() return
                if ($node is $target) then
                    element { node-name($node) } {
                        map:for-each($annotation?properties, function($key, $value) {
                            attribute { $key } { $value }
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
    let $start := anno:find-offset($node, $startOffset, $node instance of element(tei:note))
    let $end := anno:find-offset($node, $endOffset, $node instance of element(tei:note))
    let $startAdjusted :=
        if (not($start?1/.. is $node) and $start?2 = 1 and not($start?1 is $end?1)) then
            [$start?1/.., 1]
        else
            $start
    let $endAdjusted :=
        if (not($end?1/.. is $node) and $end?2 = string-length($end?1) and not($start?1 is $end?1)) then
            [$end?1/.., 1]
        else
            $end
    return
        anno:transform($node, $startAdjusted, $endAdjusted, false(), $annotation)
};

declare %private function anno:find-offset($nodes as node()*, $offset as xs:int, $isNote as xs:boolean?) {
    if (empty($nodes)) then
        ()
    else
        let $node := head($nodes)
        return
            typeswitch($node)
                case element(tei:note) return
                    if ($isNote) then
                        let $found := anno:find-offset($node/node(), $offset, ())
                        return
                            if (exists($found)) then $found else anno:find-offset(tail($nodes), $offset - string-length($node), ())
                    else
                        anno:find-offset(tail($nodes), $offset, ())
                case element() return
                    let $found := anno:find-offset($node/node(), $offset, ())
                    return
                        if (exists($found)) then $found else anno:find-offset(tail($nodes), $offset - string-length($node), ())
                case text() return
                    if ($offset <= string-length($node)) then
                        [$node, $offset]
                    else
                        anno:find-offset(tail($nodes), $offset - string-length($node), ())
                default return
                    ()
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
                else if ($inAnno and $node >> $end?1) then
                    ()
                else
                    $node
            default return
                $node
};

declare function anno:wrap($annotation as map(*), $content as function(*)) {
    let $callback := $config:annotations($annotation?type)
    return
        if (exists($callback)) then
            $callback($annotation?properties, $content)
        else
            (text { "NOT FOUND: " }, $content())
};