xquery version "3.1";

module namespace nlp="http://teipublisher.com/api/nlp";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace errors = "http://exist-db.org/xquery/router/errors";

declare function nlp:entity-recognition($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $lang := $request?parameters?lang
    let $doc := config:get-document($path)//tei:body
    let $pairs := nlp:extract-plain-text($doc)
    let $offsets := nlp:compute-offsets($pairs, 0)
    let $plain := string-join($pairs ! .?2)
    return
        switch ($request?parameters?mode)
            case "debug" return
                map {
                    "input": array { $pairs },
                    "plain": $plain,
                    "offsets": $offsets
                }
            default return
                nlp:convert(nlp:entities($plain, $lang), $offsets)
};

declare function nlp:plain-text($request as map(*)) {
    let $path := xmldb:decode($request?parameters?id)
    let $doc := config:get-document($path)//tei:body
    let $pairs := nlp:extract-plain-text($doc)
    let $plain := string-join($pairs ! .?2)
    return
        $plain
};

declare function nlp:extract-plain-text($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node() return
                nlp:extract-plain-text($node/*)
            case element(tei:p) | element(tei:head) return (
                nlp:extract-plain-text($node/node()),
                [(), "&#10;", 0]
            )
            case element() return
                nlp:extract-plain-text($node/node())
            case text() return
                if (normalize-space($node) = (" ", "")) then
                    ()
                else if ($node/.. instance of element(tei:p) and not($node/preceding-sibling::*)) then
                    [util:node-id($node/..), $node/string(), 0]
                else
                    [util:node-id($node/../..), $node/string(), string-length(string-join($node/../..//text()[. << $node]))]
            default return
                ()
};

declare function nlp:compute-offsets($pairs as array(*)*, $accum as xs:int) {
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
            nlp:compute-offsets(tail($pairs), $end)
        )
};

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

declare function nlp:entities($input as xs:string*, $lang as xs:string) {
    let $options :=
        <option>
            <stdin>
            { for $in in $input return <line>{$in}</line> }
            </stdin>
        </option>
    let $result := process:execute(("python3", config:get-repo-dir() || "/resources/scripts/nlp.entities.py", $lang), $options)
    return
        if ($result/@exitCode = "0") then
            parse-json($result/stdout/line[1]/string())
        else
            error($errors:BAD_REQUEST, "Failed to execute python: " || string-join($result/stdout/line))
};