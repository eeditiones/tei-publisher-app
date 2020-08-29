xquery version "3.1";

module namespace oapi="http://teipublisher.com/api/odd";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace router="http://exist-db.org/xquery/router" at "/db/apps/oas-router/content/router.xql";
import module namespace errors = "http://exist-db.org/xquery/router/errors" at "/db/apps/oas-router/content/errors.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare function oapi:list-odds($request as map(*)) {
    array {
        dbutil:scan-resources(xs:anyURI($config:odd-root), function ($resource) {
            if (ends-with($resource, ".odd")) then
                let $name := replace($resource, "^.*/([^/\.]+)\..*$", "$1")
                let $displayName := (
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "short"]/string(),
                    doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text(),
                    $name
                )[1]
                let $description :=  doc($resource)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/tei:desc/string()
                return
                    map {
                        "name": $name,
                        "label": $displayName,
                        "description": $description,
                        "path": $resource,
                        "canWrite": sm:has-access(xs:anyURI($resource), "rw-")
                    }
            else
                ()
        })
    }
};

declare function oapi:delete-odd($request as map(*)) {
    let $path := $config:odd-root || "/" || $request?parameters?odd
    return
        if (doc-available($path)) then
            let $deleted := xmldb:remove($config:odd-root, $request?parameters?odd)
            return
                router:response(410, ())
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};

declare %private function oapi:parse-template($nodes as node()*, $odd as xs:string, $title as xs:string?) {
    for $node in $nodes
    return
        typeswitch ($node)
            case document-node()
                return
                    oapi:parse-template($node/node(), $odd, $title)
            case element(tei:schemaSpec)
                return
                    element {node-name($node)} {
                        $node/@*,
                        attribute ident {$odd},
                        oapi:parse-template($node/node(), $odd, $title)
                    }
            case element(tei:title)
                return
                    element {node-name($node)} {
                        $node/@*,
                        $title
                    }
            case element(tei:change)
                return
                    element {node-name($node)} {
                        attribute when {current-date()},
                        "Initial version"
                    }
            case element()
                return
                    element {node-name($node)} {
                        $node/@*,
                        oapi:parse-template($node/node(), $odd, $title)
                    }
            default
                return
                    $node
};

declare function oapi:create-odd($request as map(*)) {
    let $template := doc($config:odd-root || "/template.odd.xml")
    let $parsed := document {oapi:parse-template($template, $request?parameters?odd, $request?parameters?title)}
    let $stored := xmldb:store($config:odd-root, $request?parameters?odd || ".odd", $parsed, "text/xml")
    return (
        oapi:compile($request?parameters?odd),
        router:response(201, "application/json", map {
            "path": $stored
        })
    )
};

declare %private function oapi:compile($odd) {
    for $module in ("web", "print", "latex", "epub")
    let $result :=
        pmu:process-odd(
            odd:get-compiled($config:odd-root, $odd || ".odd"),
            $config:output-root,
            $module,
            "../" || $config:output,
            $config:module-config
        )
    return
        ()
};