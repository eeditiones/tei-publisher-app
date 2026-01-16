xquery version "3.1";

module namespace deploy="https://teipublisher.org/api/deploy";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../config.xqm";
import module namespace errors = "http://e-editiones.org/roaster/errors";

declare function deploy:download-app($request as map(*)) {
    let $entries := deploy:zip-entries($config:app-root)
    let $xar := compression:zip($entries, true())
    let $name := config:expath-descriptor()/@abbrev
    return
        response:stream-binary($xar, "media-type=application/zip", $name || ".xar")
};

declare %private function deploy:zip-entries($app-collection as xs:string) {
    (: compression:zip doesn't seem to store empty collections, so we'll scan for only resources :)
    deploy:scan(xs:anyURI($app-collection), function($collection as xs:anyURI, $resource as xs:anyURI?) {
        if (exists($resource)) then
            let $relative-path := substring-after($resource, $app-collection || "/")
            return
                if (starts-with($relative-path, "transform/")) then
                    ()
                else if (util:binary-doc-available($resource)) then
                    <entry name="{$relative-path}" type="uri">{$resource}</entry>
                else
                    <entry name="{$relative-path}" type="text">
                    {
                        serialize(doc($resource), map { "indent": false() })
                    }
                    </entry>
        else
            ()
    })
};

declare %private function deploy:scan($root as xs:anyURI, $func as function(xs:anyURI, xs:anyURI?) as item()*) {
    $func($root, ()),
    if (sm:has-access($root, "rx")) then
        for $child in xmldb:get-child-resources($root)
        return
            $func($root, xs:anyURI($root || "/" || $child))
    else
        (),
    if (sm:has-access($root, "rx")) then
        for $child in xmldb:get-child-collections($root)
        return
            deploy:scan(xs:anyURI($root || "/" || $child), $func)
    else
        ()
};