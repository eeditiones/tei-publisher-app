xquery version "3.1";

module namespace vapi="http://teipublisher.com/api/view";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../lib/util.xql";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace tmpl="http://e-editiones.org/xquery/templates";
import module namespace roaster="http://e-editiones.org/roaster";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace page="http://teipublisher.com/ns/templates/page" at "../../templates/page.xqm";

declare %private function vapi:get-template($config as map(*), $template as xs:string?) {
    if ($template) then
        $template
    else
        $config?template
};

declare %private function vapi:get-config($doc as xs:string, $view as xs:string?) {
    let $document := config:get-document($doc)
    return
        if (exists($document)) then
            tpu:parse-pi(root($document), $view)
        else
            error($errors:NOT_FOUND, "document " || $doc || " not found")
};

(:~
 : Loads the templating context from context.json. 
 :
 : Adds the languages, request, and context-path to the context.
 : 
 : @param request The request map.
 : @return The merged templating context.
 :)
declare function vapi:load-config-json($request as map(*)?) {
    let $context := parse-json(util:binary-to-string(util:binary-doc($config:app-root || "/context.json")))
    return
        map:merge((
            $context,
            map {
                "languages": json-doc($config:app-root || "/resources/i18n/languages.json"),
                "request": $request,
                "context-path": $config:context-path
            }
        ))
};

(:~
: Merge the JSON config with the document/collection config
:)
declare %private function vapi:merge-config($jsonConfig as map(*), $docConfig as map(*)) {
    let $cleanedConfig := map:merge((
        (: Only keep keys that are not relevant for ODD processing :)
        for $key in map:keys($docConfig)[not(. = ('odd', 'fill', 'depth', 'media', 'view', 'template', 'output', 'type'))]
        return
            map:entry($key, $docConfig($key))
    ))
    return
        tmpl:merge-deep(($jsonConfig, $cleanedConfig))
};

(:~
 : Main endpoint for rendering an XML document via an HTML template.
 : 
 : @param request The request map.
 : @return The processed template.
 :)
declare function vapi:view($request as map(*)) {
    let $path :=
        if ($request?parameters?suffix) then
            xmldb:decode($request?parameters?docid) || $request?parameters?suffix
        else
            xmldb:decode($request?parameters?docid)
    let $config := vapi:get-config($path, $request?parameters?view)
    let $templateName := head((vapi:get-template($config, $request?parameters?template), $config:default-template))
    let $templatePaths := ($config:app-root || "/templates/pages/" || $templateName, $config:app-root || "/templates/" || $templateName)
    let $template :=
        for-each($templatePaths, function($path) {
            if (doc-available($path)) then
                doc($path)
            else
                ()
        }) => head()
    return
        if (not($template)) then
            error($errors:NOT_FOUND, "template " || $templateName || " not found")
        else
            let $templateContent := serialize($template)
            let $frontmatter := tmpl:frontmatter($templateContent)
            let $data := config:get-document($path)
            let $config := tpu:parse-pi(root($data), $request?parameters?view, $request?parameters?odd)
            let $jsonConfig := vapi:load-config-json($request)
            let $mergedConfig := vapi:merge-config($jsonConfig, $config)
            let $model := map:merge((
                $mergedConfig,
                vapi:load-context-data($mergedConfig, $frontmatter),
                map {
                    "doc": map {
                        "content": $data,
                        "path": $path,
                        "odd": replace($config?odd, '^(.*)\.odd', '$1'),
                        "view": $config?view,
                        "transform": page:transform(?, ?, $config?odd),
                        "transform-with": page:transform#3
                    },
                    "template": $templateName,
                    "media": if (map:contains($config, 'media')) then $config?media else ()
                }
            ))
            return
                tmpl:process($templateContent, $model, map {
                    "plainText": false(),
                    "resolver": vapi:resolver#1,
                    "modules": map {
                        "http://www.tei-c.org/tei-simple/config": map {
                            "prefix": "config",
                            "at": "modules/config.xqm"
                        }
                    },
                    "namespaces": map {
                        "tei": "http://www.tei-c.org/ns/1.0"
                    }
                })
};

declare function vapi:handle-error($error) {
    let $path := $config:app-root || "/templates/error-page.html"
    let $template :=
        if (doc-available($path)) then
            doc($path) => serialize()
        else if (util:binary-doc-available($path)) then
            util:binary-doc($path) => util:binary-to-string()
        else
            error($errors:NOT_FOUND, "HTML file " || $path || " not found")
    let $model := map:merge((
        vapi:load-config-json($error),
        map {
            "type": $error?code,
            "description": $error?description,
            "context-path": $config:context-path
        },
        if ($error?value?code) then
            map {
                "code": $error?value?code,
                "line": $error?value?line
            }
        else
            ()
    ))
    let $html :=
        tmpl:process($template, $model, map {
            "plainText": false(),
            "resolver": vapi:resolver#1,
            "modules": map {
                "http://www.tei-c.org/tei-simple/config": map {
                    "prefix": "config",
                    "at": "modules/config.xqm"
                }
            },
            "ignoreImports": true(),
            "ignoreUse": true()
        })
    return
        roaster:response(200, "text/html", $html)
};

declare function vapi:resolver($relPath as xs:string) as map(*)? {
    let $path := $config:app-root || "/" || $relPath
    let $content :=
        if (util:binary-doc-available($path)) then
            util:binary-doc($path) => util:binary-to-string()
        else if (doc-available($path)) then
            doc($path) => serialize()
        else
            ()
    return
        if ($content) then
            map {
                "path": $path,
                "content": $content
            }
        else
            ()
};

declare function vapi:html($request as map(*)) {
    vapi:html($request, ())
};

(:~
 : Endpoint to load and process an HTML template.
 : 
 : @param request The request map.
 : @param extConfig Additional configuration to merge with the default configuration.
 : @return The processed template.
 :)
declare function vapi:html($request as map(*), $extConfig as map(*)?) {
    let $path := $config:app-root || "/templates/" || xmldb:decode($request?parameters?file) || ".html"
    let $template :=
        if (doc-available($path)) then
            doc($path) => serialize()
        else if (util:binary-doc-available($path)) then
            util:binary-doc($path) => util:binary-to-string()
        else
            error($errors:NOT_FOUND, "HTML file " || $path || " not found")
    let $frontmatter := tmpl:frontmatter($template)
    let $config := map:merge((
        vapi:load-config-json($request),
        map {
            "context-path": $config:context-path
        },
        $extConfig
    ))
    let $context := map:merge(($config, vapi:load-context-data($config, $frontmatter)))
    return
        tmpl:process($template, $context, map {
            "plainText": false(),
            "resolver": vapi:resolver#1,
            "modules": map {
                "http://www.tei-c.org/tei-simple/config": map {
                    "prefix": "config",
                    "at": "modules/config.xqm"
                }
            },
            "namespaces": map {
                "tei": "http://www.tei-c.org/ns/1.0"
            }
        })
};

(:~
 : If a data property is present in the frontmatter, load the documents listed there and assign them to a context variable.
 :
 : The key of the map is the name of the context variable, the value is the path to the document.
 : The document is loaded using the config:get-document function.
 : The document is parsed using the tpu:parse-pi function.
 : The parsed document is returned as a map with the following properties:
 : - content: the document content
 : - path: the path to the document
 : - odd: the odd of the document
 : - view: the view of the document
 :)
declare %private function vapi:load-context-data($context as map(*), $frontmatter as map(*)) {
    for $entry in ($context?data, $frontmatter?data)
    return
        map:for-each($entry, function($key, $value) {
            let $data := config:get-document($value)
            return
                if (exists($data)) then
                    let $config := tpu:parse-pi(root($data), $config:default-view, $config:default-odd)
                    return
                        map:entry($key, map {
                            "content": $data,
                            "path": $value,
                            "odd": replace($config?odd, '^(.*)\.odd', '$1'),
                            "view": $config?view
                        })
                else
                    ()
        })
};

declare function vapi:text($request as map(*)) {
    let $path := $config:app-root || "/" || xmldb:decode($request?parameters?file) || $request?parameters?suffix
    let $template :=
        if (doc-available($path)) then
            doc($path) => serialize()
        else if (util:binary-doc-available($path)) then
            util:binary-doc($path) => util:binary-to-string()
        else
            error($errors:NOT_FOUND, "File " || $path || " not found")
     let $config := map:merge((
        vapi:load-config-json($request),
        map {
            "context-path": $config:context-path
        }
    ))
    return
        tmpl:process($template, $config, map {
            "plainText": false(),
            "resolver": vapi:resolver#1,
            "modules": map {
                "http://www.tei-c.org/tei-simple/config": map {
                    "prefix": "config",
                    "at": "modules/config.xqm"
                }
            }
        })
};
