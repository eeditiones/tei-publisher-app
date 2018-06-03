module namespace intl="http://exist-db.org/xquery/i18n/templates";

(:~
 : i18n template functions. Integrates the i18n library module. Called from the templating framework.
 :)
import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare variable $intl:LANGUAGES := ('en', 'de', 'fr', 'gr', 'pl');

(:~
 : Template function: calls i18n:process on the child nodes of $node.
 : Template parameters:
 :      lang=de Language selection
 :      catalogues=relative path    Path to the i18n catalogue XML files inside database
 :)
declare function intl:translate($node as node(), $model as map(*), $lang as xs:string?, $catalogues as xs:string?) {
    let $lang :=
        if ($lang) then (
            session:set-attribute("lang", $lang),
            $lang
        ) else
            let $sessionLang := session:get-attribute("lang")
            return
                if ($sessionLang) then
                    $sessionLang
                else
                    let $header := request:get-header("Accept-Language")
                    let $headerLang :=
                        if ($header != "") then
                            let $lang := tokenize($header, "\s*,\s*")
                            return
                                replace($lang[1], "^([^-;]+).*$", "$1")
                        else
                            $config:default-language
                    let $lang :=
                        if ($headerLang = ('de', 'fr', 'it')) then
                            $headerLang
                        else
                            $config:default-language
                    return (
                        session:set-attribute("lang", $lang),
                        $lang
                    )
    let $cpath :=
        (: if path to catalogues is relative, resolve it relative to the app root :)
        if (starts-with($catalogues, "/")) then
            $catalogues
        else
            concat($config:app-root, "/", $catalogues)
    let $processed := templates:process($node/*, $model)
    let $translated :=
        i18n:process($processed, $lang, $cpath, ())
    return
        element { node-name($node) } {
            $node/@*,
            $translated
        }
};
