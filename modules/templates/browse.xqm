xquery version "3.1";

module namespace browse="http://teipublisher.com/ns/templates/browse";

import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../lib/util.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../query.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function browse:parent-link($context as map(*)) {
    let $parts := 
        if (exists($context?doc)) then
            config:get-relpath($context?doc?content, $config:data-default) => tokenize("/")
        else
            head(($context?request?parameters?path, $context?request?parameters?docid)) => tokenize("/")
    return
        string-join(subsequence($parts, 1, count($parts) - 1), "/")
};

declare function browse:is-writable($context as map(*)) {
    let $path := $config:data-root || "/" || $context?request?parameters?path
    let $writable := sm:has-access(xs:anyURI($path), "rw-")
    return
        if ($writable) then "writable" else ""
};

declare function browse:document-options($doc as element()) {
    let $config := tpu:parse-pi(root($doc), ())
    return map:merge((
        $config,
        map {
            "relpath": config:get-identifier($doc),
            "odd": head(($config?odd, $config:default-odd))
        }
    ))
};

declare function browse:header($context as map(*), $doc as element()) {
    browse:header($context, $doc, browse:document-options($doc))
};

declare function browse:header($context as map(*), $doc as element(), $config as map(*)) {
    try {
        let $teiHeader := nav:get-header($config, root($doc)/*)
        let $header :=
            $pm-config:web-transform($teiHeader, map {
                "display": "browse",
                "doc": if ($config:address-by-id) then config:get-identifier($doc) else $config:context-path || "/" || $config?relpath,
                "language": $context?language
            }, $config?odd)
        return
            if ($header) then
                $header
            else
                <a href="{$config?relPath}">{$config?relPath}</a>
    } catch * {
        <a href="{$config?relPath}">{util:document-name($doc)}</a>,
        <p class="error">Failed to output document metadata: {$err:description}</p>
    }
};

declare function browse:show-hits($context as map(*), $doc as element()) {
    if (exists($context?request?parameters?query) and $context?request?parameters?query != '') then
        let $fieldName := head(($context?request?parameters?field, "text"))
        for $field in ft:highlight-field-matches($doc, query:field-prefix($doc) || $fieldName)
        let $matches := $field//exist:match
        return
            if (count($matches)) then 
                <div class="matches">
                    <div class="count"><pb-i18n key="browse.items" options='{{"count": {count($matches)}}}'></pb-i18n></div>
                    {
                        for $match in subsequence($matches, 1, 5)
                        let $config := <config width="60" table="no"/>
                        return
                            kwic:get-summary($field, $match, $config)
                    }
                </div>
            else ()
    else
        ()
};