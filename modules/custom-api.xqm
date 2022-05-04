xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace bapi="http://teipublisher.com/api/blog" at "blog.xqm";
import module namespace dapi="http://teipublisher.com/api/documents" at "lib/api/document.xqm";
import module namespace errors = "http://exist-db.org/xquery/router/errors";
import module namespace rutil="http://exist-db.org/xquery/router/util";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";

declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function api:html($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    return
        if ($doc) then
            let $xml := config:get-document($doc)
            return
                if (exists($xml)) then
                    let $config := tpu:parse-pi(root($xml), ())
                    let $title :=
                        $pm-config:web-transform(
                            $xml//tei:teiHeader//tei:title,
                            map { "root": $xml, "view": "metadata", "webcomponents": 7},
                            $config?odd
                        )
                    let $content :=
                        $pm-config:web-transform(
                            $xml//tei:text,
                            map { "root": $xml, "webcomponents": 7 },
                            $config?odd
                        )                        
                    let $locales := "resources/i18n/{{ns}}/{{lng}}.json"
                    let $page :=
                            <html>
                                <head>
                                    <meta charset="utf-8"/>
                                    <link rel="stylesheet" type="text/css" href="https://teipublisher.com/exist/apps/tei-publisher/resources/css/theme.css"/>                                       
                                </head>
                                <body class="printPreview">
                                    <paper-button id="closePage" class="hidden-print" onclick="window.close()" title="close this page">
                                        <paper-icon-button icon="close"></paper-icon-button>
                                        Close Page
                                    </paper-button>
                                    <paper-button id="printPage" class="hidden-print" onclick="window.print()" title="print this page">
                                        <paper-icon-button icon="print"></paper-icon-button>
                                        Print Page
                                    </paper-button>

                                    <pb-page unresolved="unresolved" locales="{$locales}" locale-fallback-ns="app" require-language="require-language" api-version="1.0.0">
                                        <h2 class="letter-title">
                                            { $title }
                                        </h2>
                                            { $content }
                                    </pb-page>
                                </body>
                            </html>
                    return
                        dapi:postprocess($page, (), $config?odd, $config:context-path || "/", true())
                else
                    error($errors:NOT_FOUND, "Document " || $doc || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
};