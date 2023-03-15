xquery version "3.1";

module namespace nlp="http://teipublisher.com/api/nlp";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace nlp-config="http://teipublisher.com/api/nlp/config" at "../../nlp-config.xqm";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace router="http://e-editiones.org/roaster";

declare function nlp:status($request as map(*)) {
    try {
        let $request := <http:request method="GET" timeout="10"/>
        let $response := http:send-request($request, $nlp-config:api-endpoint || "/status/")
        return
            if ($response[1]/@status = "200") then
                parse-json(util:binary-to-string($response[2]))
            else
                error($errors:BAD_REQUEST, $response[2])
    } catch * {
        error($errors:NOT_FOUND, "Failed to connect to NER API endpoint")
    }
};

declare function nlp:models($request as map(*)) {
    let $request := 
        <http:request method="GET" timeout="10"/>
    return
        try {
            let $response := http:send-request($request, $nlp-config:api-endpoint || "/model")
            return
                if ($response[1]/@status = "200") then
                    parse-json(util:binary-to-string($response[2]))
                else
                    error($errors:BAD_REQUEST, $response[2])
        } catch * {
            error($errors:NOT_FOUND)
        }
};

declare function nlp:entity-recognition($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($path)/tei:TEI/tei:text
    let $pairs := (
        nlp:extract-plain-text($doc, true()), 
        nlp:extract-plain-text($doc//tei:note, false())
    )
    let $offsets := nlp:mapping-table($pairs, 0, $request?parameters?debug)
    let $plain := string-join($pairs ! .?2)
    return
        if ($request?parameters?debug) then
            map {
                "plain": $plain,
                "offsets": $offsets
            }
        else
            nlp:convert(nlp:entities-remote($plain, $request?parameters?model), $offsets)
};

declare function nlp:plain-text($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($path)/tei:TEI/tei:text
    let $pairs := (
        nlp:extract-plain-text($doc, true()), 
        nlp:extract-plain-text($doc//tei:note, false())
    )
    let $plain := string-join($pairs ! .?2)
    return
        $plain
};

declare function nlp:train-model($request as map(*)) {
    let $base := $request?parameters?base
    let $name := $request?parameters?name
    let $lang := $request?parameters?lang
    let $vectors := $request?parameters?copy_vectors
    let $data := nlp:train($request)
    let $pid := nlp:train-remote($name, $base, $lang, $vectors, $data)
    return $pid
};

declare function nlp:train($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $document := config:get-document($path)
    let $input :=
        if ($document) then
            $document//tei:body
        else
            collection($config:data-root || "/" || $path)//tei:body
    return
        if (exists($input)) then
            for $doc in $input
            return (
                nlp:training-data-from-blocks(nlp-config:blocks($doc, false()), false()),
                nlp:training-data-from-blocks(nlp-config:blocks($doc, true()), true())
            )
        else
            error($errors:NOT_FOUND, "Training data not found: " || $path)
};

declare function nlp:log($request as map(*)) {
    let $pid := $request?parameters?pid
    return
        try {
            let $request := <http:request method="GET" timeout="10"/>
            let $response := http:send-request($request, $nlp-config:api-endpoint || "/train/" || $pid)
            return
                router:response($response[1]/@status, "text/text", $response[2])
        } catch * {
            error($errors:NOT_FOUND, "Failed to connect to NER API endpoint")
        }
};

declare %private function nlp:training-data-from-blocks($blocks as element()*, $processFn as xs:boolean?) {
    for $block in $blocks
    let $data := nlp:training-data($block, $processFn)
    let $plain := string-join($data ! .?2)
    let $entities := array { nlp:collect-training-entities($data, 0, ()) }
    return
        map {
            "source": substring-after(document-uri(root($block)), $config:data-root || "/"),
            "text": $plain,
            "entities": $entities
        }
};

(:~
 : Scan the sequence of arrays returned by nlp:training-data and extract the entities found,
 : recomputing the offsets.
 :)
declare %private function nlp:collect-training-entities($data as array(*)*, $offset as xs:int, $result as array(*)*) {
    if (exists($data)) then
        let $head := head($data)
        let $end := $offset + string-length($head?2)
        return (
            if ($head?1 = $nlp-config:entities) then
                nlp:collect-training-entities(tail($data), $end, ($result, [ $offset, $end, $head?1]))
            else
                nlp:collect-training-entities(tail($data), $end, $result)
        )
    else
        $result
};

(:~
 : Generate training data: returns a sequence of arrays containing an entity name or the empty sequence as first,
 : a text fragment as 2nd item.
 :)
declare %private function nlp:training-data($nodes as node()*, $outputNotes as xs:boolean?) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                nlp:training-data($node/*, $outputNotes)
            case element(tei:note) return 
                if ($outputNotes) then
                    nlp:training-data($node/node(), $outputNotes)
                else
                    ()
            case element() return
                let $type := nlp-config:entity-type($node)
                return
                    if ($type) then
                        [$type, nlp:normalize($node)]
                    else
                    nlp:training-data($node/node(), $outputNotes)
            case text() return
                [(), replace($node/string(), "[\s\n]{2,}|\n", " ")]
            default return
                ()
};

declare %private function nlp:normalize($input as xs:string) {
    replace($input, "[\s\n]{2,}|\n", " ") => replace("^\W+", "") => replace("\W+$", "")
};

(:~
 : Extract the plain text of the document while recording the node id and 
 : character offset of each text node.
 :
 : @return a sequence of arrays with the first array element containing the
 : id of the text node, the second the text, and the third the absolute character
 : offset into the parent node
 :)
declare function nlp:extract-plain-text($nodes as node()*, $skipNotes as xs:boolean?) {
    for $node at $pos in $nodes
    return
        typeswitch ($node)
            case document-node() return
                nlp:extract-plain-text($node/*, $skipNotes)
            case element(tei:p) | element(tei:head) return (
                nlp:extract-plain-text($node/node(), $skipNotes),
                (: output empty line :)
                [(), " ", 0]
            )
            case element(tei:note) return 
                if ($skipNotes) then
                    ()
                else
                (
                    (: output empty line before footnote starts :)
                    [(), " ", 0],
                    nlp:extract-plain-text($node/node(), $skipNotes)
                ) 
            case element() return
                nlp:extract-plain-text($node/node(), $skipNotes)
            case text() return
                    let $parent := $node/..
                    let $text :=
                        if (matches($node, "^[\s\n]+$")) then
                            ' '
                        else
                            $node/string()
                    return
                        (: if there are preceding siblings, we need to calculate the absolute character offset within the parent node:)
                        if ($pos > 1) then
                            [$parent, $text, nlp:absolute-offset($parent/node()[. << $node], 0)]
                        else
                            [$parent, $text, 0]
            default return
                ()
};

(:~
 : Accumulate the string lengths of a sequence of nodes to obtain an absolute character
 : offset. Some elements need special treatment, e.g. tei:note should be ignored.
 :)
declare %private function nlp:absolute-offset($nodes as node()*, $start as xs:int) {
    if ($nodes) then
        let $head := head($nodes)
        let $offset :=
            typeswitch($head)
                case element(tei:note) return
                    $start
                case element() return
                    nlp:absolute-offset($head/node(), $start)
                case comment() | processing-instruction() return
                    $start
                default return
                    $start + string-length($head)
        return
            nlp:absolute-offset(tail($nodes), $offset)
    else
        $start
};

(:~
 : Processes the sequence of arrays returned by nlp:plain-text and return
 : a map for each, mapping the absolute offset of the text fragment in the
 : plain text to the corresponding XML node and original offset.
 :
 : The resulting data structure is later used by nlp:convert to re-map the
 : detected entities back to the XML being annotated.
 :)
declare function nlp:mapping-table($pairs as array(*)*, $accum as xs:int, $debug as xs:boolean?) {
    nlp:mapping-table((), $pairs, $accum, $debug)
};

declare function nlp:mapping-table($result as map(*)*, $pairs as array(*)*, $accum as xs:int, $debug as xs:boolean?) {
    if (empty($pairs)) then
        $result
    else
        let $pair := head($pairs)
        let $end := $accum + string-length($pair?2)
        let $entry :=
            if (exists($pair?1)) then
                map {
                    "node": if ($debug) then util:node-id($pair?1) else $pair?1,
                    "start": $accum,
                    "end": $end,
                    "origOffset": $pair?3
                }
            else
                ()
        return
            nlp:mapping-table(($result, $entry), tail($pairs), $end, $debug)
};

(:~
 : For each entity found, create a JSON annotation record which can be consumed
 : by the annotation editor. Uses the mapping created by nlp:compute-offsets
 : to re-map each entity to the original XML.
 :)
declare function nlp:convert($entities as array(*), $offsets as map(*)*) {
    array {
        for $entity in $entities?*
        let $insertPoint := filter($offsets, function($offset as map(*)) {
            $entity?start >= $offset?start and $entity?start < $offset?end
        })
        (: ignore if the element is already marked as entity :)
        where empty(nlp-config:entity-type($insertPoint?node))
        let $start := xs:int($entity?start - $insertPoint?start[1])
        return
            map {
                "context": util:node-id($insertPoint?node),
                "start": $insertPoint?origOffset + $start,
                "end": $insertPoint?origOffset + $start + string-length($entity?text),
                "type": $entity?type,
                "text": $entity?text,
                "properties": map {
                    "ref": ""
                }
            }
    }
};

declare function nlp:pattern-recognition($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $lang := $request?parameters?lang
    let $doc := config:get-document($path)/tei:TEI
    let $text := $doc/tei:text
    let $patterns := nlp:person-patterns($doc)
    let $pairs := (
        nlp:extract-plain-text($text, true()), 
        nlp:extract-plain-text($text//tei:note, false())
    )
    let $offsets := nlp:mapping-table($pairs, 0, $request?parameters?debug)
    let $plain := string-join($pairs ! .?2)
    return
        if ($request?parameters?debug) then
            map {
                "plain": $plain,
                "offsets": $offsets,
                "patterns": $patterns
            }
        else
            nlp:convert(nlp:patterns-remote($plain, $patterns, $lang), $offsets)
};

declare %private function nlp:person-patterns($doc as element(tei:TEI)) {
    let $patterns :=
        for $name in $doc//tei:listPerson/tei:person/tei:persName[not(@type)]
        return
            if ($name/tei:surname) then
                nlp:to-pattern($name/tei:forename, $name/tei:surname)
            else if (contains($name, ',')) then
                let $names := tokenize($name, ",\s*")
                return
                    nlp:to-pattern($names[2], $names[1])
            else
                map { "lower": $name/string() }
    return
        array {
            for $p in $patterns
            return
                map {
                    "label": "PER",
                    "pattern": $p
                }
        }
};

declare %private function nlp:to-pattern($forename as xs:string, $surname as xs:string) {
    let $forename := lower-case($forename)
    return
        [
            map {
                "lower": map {
                    "regex": substring($forename, 1, 1) || "(?:\.|" ||
                        substring($forename, 2) || ")"
                },
                "op": "?"
            },
            map {
                "lower": map {
                    "regex": lower-case($surname) || "\'?s?"
                }
            }
        ]
};

declare function nlp:entities-remote($input as xs:string*, $model as xs:string) {
    let $request := 
        <http:request method="POST" timeout="10">
            <http:body media-type="text/text"/>
        </http:request>
    let $response := http:send-request(
            $request, 
            $nlp-config:api-endpoint || "/entities/" || $model,
            string-join($input))
    return
        if ($response[1]/@status = "200") then
            parse-json(util:binary-to-string($response[2]))
        else
            error($errors:BAD_REQUEST, $response[2])
};

declare function nlp:patterns-remote($input as xs:string*, $patterns as array(*), $lang as xs:string) {
    let $request := 
        <http:request method="POST" timeout="10">
            <http:body media-type="application/json"/>
        </http:request>
    let $body := map {
        "lang": $lang,
        "text": string-join($input),
        "patterns": $patterns
    }
    let $serialized := util:string-to-binary(serialize($body, map { "method": "json" }))
    let $response := 
        http:send-request(
            $request, 
            $nlp-config:api-endpoint || "/patterns/",
            $serialized
        )
    return
        if ($response[1]/@status = "200") then
            parse-json(util:binary-to-string($response[2]))
        else
            error($errors:BAD_REQUEST, $response[2])
};

declare function nlp:train-remote($name, $base, $lang, $vectors, $data) {
    let $request := 
        <http:request method="POST">
            <http:body media-type="application/json"/>
        </http:request>
    let $body := map {
        "name": $name,
        "base": $base,
        "lang": $lang,
        "copy_vectors": $vectors,
        "samples": $data
    }
    let $serialized := util:string-to-binary(serialize($body, map { "method": "json" }))
    let $response := http:send-request($request, $nlp-config:api-endpoint || "/train/", $serialized)
    return
        if ($response[1]/@status = "200") then
            parse-json(util:binary-to-string($response[2]))
        else
            error($errors:BAD_REQUEST, parse-json(util:binary-to-string($response[2])))
};