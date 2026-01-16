xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

declare variable $idx:registers := collection($idx:app-root || '/data/registers');

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "persName" return
                for $p in $header//tei:correspDesc/tei:correspAction/tei:persName/@key
                return 
                    idx:resolve-person($p)
            case "person" return
                for $persName in (
                    $header//tei:correspDesc/tei:correspAction/tei:persName/@key,
                    $root//tei:text//tei:persName/@key
                )
                return
                    $persName
            case "place" return
                for $placeName in (
                    $header//tei:correspDesc/tei:correspAction/tei:placeName/@key,
                    $root//tei:text//tei:placeName/@key
                )
                return 
                    $placeName
            case "year" return 
                substring($header//tei:correspDesc/tei:correspAction/tei:date/@when, 1, 4)
            case "title" return
                string-join((
                    $header//tei:msDesc/tei:head, $header//tei:titleStmt/tei:title[@type = 'main'],
                    $header//tei:titleStmt/tei:title,
                    $root/dbk:info/dbk:title,
                    root($root)//article-meta/title-group/article-title,
                    root($root)//article-meta/title-group/subtitle
                ), " - ")
            case "language" return
                head((
                    $header//tei:langUsage/tei:language/@ident,
                    (: rule for Serafin letters :)
                    $root//tei:text[@type="source"]/@xml:lang,
                    $root/@xml:lang,
                    $header/@xml:lang,
                    root($root)/*/@xml:lang
                ))
            case "date" return
                idx:get-date(($header//tei:correspDesc/tei:correspAction[@type="sent"]/tei:date[1]))
            case "genre" return (
                idx:get-genre($header),
                root($root)//dbk:info/dbk:keywordset[@role="genre"]/dbk:keyword,
                root($root)//article-meta/kwd-group[@kwd-group-type="genre"]/kwd
            )
            case "category" return
                (root($root)/tei:TEI/@n, "ZZZ")[1]
            case "feature" return (
                idx:get-classification($header, 'feature'),
                $root/dbk:info/dbk:keywordset[@role="feature"]/dbk:keyword
            )
            case "form" return (
                idx:get-classification($header, 'form'),
                $root/dbk:info/dbk:keywordset[@role="form"]/dbk:keyword
            )
            case "period" return (
                idx:get-classification($header, 'period'),
                $root/dbk:info/dbk:keywordset[@role="period"]/dbk:keyword
            )
            case "content" return (
                root($root)//body,
                $root/dbk:section
            )
            default return
                ()
};

declare function idx:resolve-person($key) {
    $idx:registers/id($key)/tei:persName
};

declare function idx:resolve-place($key) {
    $idx:registers/id($key)/tei:placeName
};

declare function idx:get-genre($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-classification($header as element()?, $scheme as xs:string) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#" || $scheme]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-date($date)  {
    if($date/@when)
        then xs:date(idx:normalize-date($date/@when/string()))
    else if($date/@notBefore)
        then xs:date(idx:normalize-date($date/@notBefore/string()))
    else if($date/@notAfter)
        then xs:date(idx:normalize-date($date/@notAfter/string()))
    else (
    )
};

declare function idx:normalize-date($date as xs:string) {
    if (matches($date, "^\d{4}-\d{2}$")) then
        $date || "-01"
    else if (matches($date, "^\d{4}$")) then
        $date || "-01-01"
    else
        $date
};