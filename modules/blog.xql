xquery version "3.1";

(:~
 : A module with custom API functions defined in `custom-api.json`.
 :)
module namespace bapi="http://teipublisher.com/api/blog";

declare namespace dbk="http://docbook.org/ns/docbook";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace vapi="http://teipublisher.com/api/view" at "lib/api/view.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare function bapi:article($request as map(*)) {
    let $newRequest := map:merge((
        $request,
        map {
            "parameters": map:merge(($request?parameters, map { 
                    "docid": "doc/blog/" || $request?parameters?article,
                    "template": "blog.html"
            }))
        }
    ))
    return
        vapi:view($newRequest)
};

declare function bapi:home($request as map(*)) {
    let $lastEntry := util:document-name(
        head(
            for $article in collection($config:data-root || "/doc/blog")/dbk:article
            let $published := $article/dbk:info/dbk:pubdate
            order by xs:date($published) descending
            return
                $article
        )
    )
    let $newRequest := map:merge((
        $request,
        map {
            "parameters": map:merge(($request?parameters, 
                map { "docid": "doc/blog/" || $lastEntry, "template": "blog.html"}))
        }
    ))
    return
        vapi:view($newRequest)
};

declare function bapi:list($request as map(*)) {
    <ul>
    {
        let $doc := $request?parameters?doc
        for $article in collection($config:data-root || "/doc/blog")/*
        let $date := (
            $article/dbk:info/dbk:pubdate,
            xmldb:last-modified(util:collection-name($article), util:document-name($article))
        )[1]
        let $options := map {
            "mode": "summary",
            "root": $article,
            "active": $doc,
            "skipAuthors": true(),
            "path": substring-after(document-uri(root($article)), $config:data-root || '/')
        }
        order by xs:date($date) descending
        return
            <li class="{if ($doc = $options?path) then 'active' else ()}">
                <article>
                {
                    $pm-config:web-transform($article, $options, "docbook.odd")
                }
                </article>
            </li>
    }
    </ul>
};