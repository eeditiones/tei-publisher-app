xquery version "3.1";

declare namespace dbk="http://docbook.org/ns/docbook";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

<ul>
{
    let $doc := request:get-parameter("doc", ())
    for $article in collection($config:data-root || "/doc/blog")/*
    let $date := (
        $article/dbk:info/dbk:pubdate,
        xmldb:last-modified(util:collection-name($article), util:document-name($article))
    )[1]
    let $options := map {
        "mode": "summary",
        "root": $article,
        "active": $doc,
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
