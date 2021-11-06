xquery version "3.1";

module namespace nlp="http://teipublisher.com/api/nlp";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace anno-config="http://teipublisher.com/api/annotations/config" at "../../annotation-config.xqm";
import module namespace errors = "http://exist-db.org/xquery/router/errors";

declare function nlp:entity-recognition($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($path)//tei:body
    let $pairs := nlp:extract-plain-text($doc)
    let $offsets := nlp:mapping-table($pairs, 0)
    let $plain := string-join($pairs ! .?2)
    return
        if ($request?parameters?debug) then
            map {
                "plain": $plain,
                "offsets": $offsets
            }
        else
            nlp:convert(nlp:entities($plain), $offsets)
};

declare function nlp:plain-text($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($path)//tei:body
    let $pairs := nlp:extract-plain-text($doc)
    let $plain := string-join($pairs ! .?2)
    return
        $plain
};

declare function nlp:train($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $document := config:get-document($path)
    let $input :=
        if ($document) then
            $document//tei:body
        else
            collection($config:data-root || "/" || $path)//tei:body
    for $doc in $input
    return (
        for $block in $doc/(descendant::tei:p|descendant::tei:head)
        let $data := nlp:training-data($block, false())
        let $plain := string-join($data ! .?2)
        let $entities := array { nlp:collect-training-entities($data, 0, ()) }
        return
            map {
                "source": substring-after(document-uri(root($doc)), $config:data-root || "/"),
                "text": $plain,
                "entities": $entities
            },
        for $block in $doc//tei:note
        let $data := nlp:training-data($block, true())
        let $plain := string-join($data ! .?2)
        let $entities := array { nlp:collect-training-entities($data, 0, ()) }
        return
            map {
                "source": substring-after(document-uri(root($doc)), $config:data-root || "/"),
                "text": $plain,
                "entities": $entities
            }
    )
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
            if ($head?1 = ("PER", "LOC")) then
                nlp:collect-training-entities(tail($data), $end, ($result, [ $head?1, $offset, $end]))
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
            case element(tei:persName) | element(tei:author) return
                ["PER", nlp:normalize($node)]
            case element(tei:placeName) | element(tei:pubPlace) return
                ["LOC", nlp:normalize($node)]
            case element() return
                nlp:training-data($node/node(), $outputNotes)
            case text() return
                    [(), replace($node/string(), "[\s\n]{2,}", " ")]
            default return
                ()
};

declare %private function nlp:normalize($input as xs:string) {
    replace($input, "[\s\n]{2,}", " ") => replace("^\W+", "") => replace("\W+$", "")
};

(:~
 : Extract the plain text of the document while recording the node id and 
 : character offset of each text node.
 :
 : @return a sequence of arrays with the first array element containing the
 : id of the text node, the second the text, and the third the absolute character
 : offset into the parent node
 :)
declare function nlp:extract-plain-text($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                nlp:extract-plain-text($node/*)
            case element(tei:p) | element(tei:head) return (
                nlp:extract-plain-text($node/node()),
                (: output empty line :)
                [(), "&#10;", 0]
            )
            case element(tei:note) return (
                (: output empty line before footnote starts :)
                [(), "&#10;", 0],
                nlp:extract-plain-text($node/node())
            ) case element() return
                nlp:extract-plain-text($node/node())
            case text() return
                if (normalize-space($node) = (" ", "")) then
                    ()
                (: if there are preceding siblings, we need to calculate the absolute character offset within the parent node:)
                else if ($node/preceding-sibling::node()) then
                    [util:node-id($node/..), $node/string(), nlp:absolute-offset($node/../node()[. << $node], 0)]
                else
                    [util:node-id($node/..), $node/string(), 0]
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
declare function nlp:mapping-table($pairs as array(*)*, $accum as xs:int) {
    if (empty($pairs)) then
        ()
    else
        let $pair := head($pairs)
        let $end := $accum + string-length($pair?2)
        return (
            if (exists($pair?1)) then
                map {
                    "node": $pair?1,
                    "start": $accum,
                    "end": $end,
                    "origOffset": $pair?3
                }
            else
                (),
            nlp:mapping-table(tail($pairs), $end)
        )
};

(:~
 : For each entity found, create a JSON annotation record which can be consumed
 : by the annotation editor. Uses the mapping created by nlp:compute-offsets
 : to re-map each entity to the original XML.
 :)
declare function nlp:convert($entities as array(*), $offsets as map(*)*) {
    for $entity in $entities?*
    let $insertPoint := filter($offsets, function($offset as map(*)) {
        $entity?start >= $offset?start and $entity?start < $offset?end
    })
    let $start := xs:int($entity?start - $insertPoint?start[1])
    return
        map {
            "context": $insertPoint?node,
            "start": $insertPoint?origOffset + $start,
            "end": $insertPoint?origOffset + $start + string-length($entity?text),
            "type": $entity?type,
            "text": $entity?text,
            "properties": map {}
        }
};

declare %private function nlp:entities($input as xs:string*) {
    let $options :=
        <option>
            <stdin>
            { for $in in $input return <line>{$in}</line> }
            </stdin>
        </option>
    let $result := process:execute(($anno-config:ner-python-path, config:get-repo-dir() || "/resources/scripts/nlp.entities.py", "--model", $anno-config:ner-model), $options)
    return
        if ($result/@exitCode = "0") then
            parse-json($result/stdout/line[1]/string())
        else
            error($errors:BAD_REQUEST, "Failed to execute python: " || string-join($result/stdout/line))
};