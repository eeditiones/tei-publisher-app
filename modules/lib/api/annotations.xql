xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare function anno:save($request as map(*)) {
    let $annotations := $request?body
    let $path := xmldb:decode($request?parameters?path)
    let $doc := config:get-document($path)
    return
        if ($doc) then
            let $map := map:merge(
                for $annoGroup in $annotations?*
                group by $id := $annoGroup?context
                let $node := util:node-by-id($doc, $id)
                return
                    map:entry($node, anno:apply($node, $annoGroup))
            )
            return
                anno:merge($doc, $map)
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};

declare %private function anno:merge($nodes as node()*, $elements as map(*)) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document { anno:merge($node/node(), $elements) }
            case element() return
                let $replacement := $elements($node)
                return
                    if ($replacement) then 
                        $replacement
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
        let $output := anno:apply($node, $anno?start + 1, $anno?end + 1, $anno)
        return
            anno:apply($output, tail($annotations))
};

declare %private function anno:apply($node as node(), $startOffset as xs:int, $endOffset as xs:int, $annotation as map(*)) {
    let $start := anno:find-offset($node, $startOffset)
    let $end := anno:find-offset($node, $endOffset)
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
    let $log := util:log('INFO', ($startAdjusted, $endAdjusted))
    return
        anno:transform($node, $startAdjusted, $endAdjusted, false(), $annotation)
};

declare %private function anno:find-offset($nodes as node()*, $offset as xs:int) {
    if (empty($nodes)) then
        ()
    else
        let $node := head($nodes)
        return
            typeswitch($node)
                case element(tei:note) return
                    anno:find-offset(tail($nodes), $offset)
                case element() return
                    let $found := anno:find-offset($node/node(), $offset)
                    return
                        if (exists($found)) then $found else anno:find-offset(tail($nodes), $offset - string-length($node))
                case text() return
                    if ($offset <= string-length($node)) then
                        [$node, $offset]
                    else
                        anno:find-offset(tail($nodes), $offset - string-length($node))
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
    let $localName := if ($annotation?tag) then $annotation?tag else 'hi'
    return
        element { QName("http://www.tei-c.org/ns/1.0", $localName) } {
            map:for-each($annotation?properties, function($key, $value) {
                attribute { $key } { $value }
            }),
            $content() 
        }
};