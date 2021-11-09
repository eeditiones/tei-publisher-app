xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations/config";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare variable $anno:local-authority-file := $config:data-root || "/register.xml";

(:~
 : Named entity recognition: endpoint of the python API
 :)
declare variable $anno:ner-api-endpoint := "http://localhost:8001";

(:~
 : Create TEI for the given type, properties and content of an annotation and return it.
 : This function is called when annotations are merged into the original TEI.
 :)
declare function anno:annotations($type as xs:string, $properties as map(*)?, $content as function(*)) {
    switch ($type)
        case "person" return
            <persName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</persName>
        case "place" return
            <placeName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</placeName>
        case "term" return
            <term xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</term>
        case "organization" return
            <orgName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</orgName>
        case "hi" return
            <hi xmlns="http://www.tei-c.org/ns/1.0">
            { 
                if ($properties?rend) then attribute rend { $properties?rend } else (),
                if ($properties?rendition) then attribute rendition { $properties?rendition } else (),
                $content()
            }
            </hi>
        case "abbreviation" return
            <choice xmlns="http://www.tei-c.org/ns/1.0"><abbr>{$content()}</abbr><expan>{$properties?expan}</expan></choice>
        case "sic" return
            <choice xmlns="http://www.tei-c.org/ns/1.0"><sic>{$content()}</sic><corr>{$properties?corr}</corr></choice>
        case "reg" return
            <choice xmlns="http://www.tei-c.org/ns/1.0"><orig>{$content()}</orig><reg>{$properties?reg}</reg></choice>
        case "note" return
            <seg xmlns="http://www.tei-c.org/ns/1.0" type="annotated">{$content()}
            <note xmlns="http://www.tei-c.org/ns/1.0" type="annotation">{$properties?note}</note></seg>
        case "date" return
            <date xmlns="http://www.tei-c.org/ns/1.0">
            {
                for $prop in map:keys($properties)[. = ('when', 'from', 'to')]
                return
                    attribute { $prop } { $properties($prop) },
                $content()
            }
            </date>
        case "app" return
            <app xmlns="http://www.tei-c.org/ns/1.0">
                <lem>{$content()}</lem>
                {
                    for $prop in map:keys($properties)[starts-with(., 'rdg')]
                    let $n := replace($prop, "^.*\[(.*)\]$", "$1")
                    order by number($n)
                    return
                        <rdg wit="{$properties('wit[' || $n || ']')}">{$properties($prop)}</rdg>
                }
            </app>
        case "link" return
            <ref xmlns="http://www.tei-c.org/ns/1.0" target="{$properties?target}">{$content()}</ref>
        case "edit" return
            $properties?content
        default return
            $content()
};

(:~
 : Search for existing occurrences of annotations of the given type and key
 : in the data collection.
 :
 : Used to display the occurrence count next to authority entries.
 :)
declare function anno:occurrences($type as xs:string, $key as xs:string) {
    switch ($type)
        case "person" return
            collection($config:data-default)//tei:persName[@ref = $key]
        case "place" return
            collection($config:data-default)//tei:placeName[@ref = $key]
        case "term" return
            collection($config:data-default)//tei:term[@ref = $key]
        case "organization" return
            collection($config:data-default)//tei:orgName[@ref = $key]
         default return ()
};

(:~
 : Create a local copy of an authority record based on the given type, id and data
 : passed in by the client.
 :)
declare function anno:create-record($type as xs:string, $id as xs:string, $data as map(*)) {
    switch ($type)
        case "place" return
            <place xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <placeName type="full">{$data?name}</placeName>
                {
                    if (exists($data?lat) and exists($data?lng)) then
                        <location>
                            <geo>{string-join(($data?lat,  $data?lng), ' ')}</geo>
                        </location>
                    else
                        ()
                }
                <country>{$data?country}</country>
                <region>{$data?region}</region>
                <note>{$data?note}</note>
                <ptr type="geonames" target="{$data?links?1}"/>
                {
                    array:subarray($data?links, 2) => array:for-each(function ($link) {
                        <ptr xmlns="http://www.tei-c.org/ns/1.0" type="info" target="{$link}"/>
                    })
                }
            </place>
        case "person" return
            <person xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <persName type="full">{$data?name}</persName>
                {
                    if (exists($data?birth)) then
                        <birth when="{$data?birth}"/>
                    else
                        (),
                    if (exists($data?death)) then
                        <death when="{$data?death}"/>
                    else
                        ()
                }
                <note>{$data?note}</note>
                {
                    if (exists($data?profession)) then
                        for $prof in $data?profession?*
                        return
                            <occupation>{$prof}</occupation>
                    else
                        ()
                }
            </person>
        case "organization" return
            <org xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <orgName type="full">{$data?name}</orgName>
            </org>
        case "term" return
            <category xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <catDesc>{$data?name}</catDesc>
            </category>
        default return
            ()
};

(:~
 : Query the local register for existing authority entries matching the given type and query string. 
 :)
declare function anno:query($type as xs:string, $query as xs:string?) {
    try {
        switch ($type)
            case "place" return
                for $place in doc($anno:local-authority-file)//tei:place[ft:query(tei:placeName, $query)]
                return
                    map {
                        "id": $place/@xml:id/string(),
                        "label": $place/tei:placeName[@type="full"]/string(),
                        "details": ``[`{$place/tei:note/string()}` - `{$place/tei:country/string()}`, `{$place/tei:region/string()}`]``,
                        "link": $place/tei:ptr/@target/string()
                    }
            case "person" return
                for $person in doc($anno:local-authority-file)//tei:person[ft:query(tei:persName, $query)]
                return
                    map {
                        "id": $person/@xml:id/string(),
                        "label": $person/tei:persName[@type="full"]/string(),
                        "details": ``[`{$person/tei:note/string()}` - `{$person/tei:country/string()}`, `{$person/tei:region/string()}`]``,
                        "link": $person/tei:ptr/@target/string()
                    }
            case "organization" return
                for $org in doc($anno:local-authority-file)//tei:org[ft:query(tei:orgName, $query)]
                return
                    map {
                        "id": $org/@xml:id/string(),
                        "label": $org/tei:orgName[@type="full"]/string(),
                        "details": $org/tei:note/string(),
                        "link": $org/tei:ptr/@target/string()
                    }
            case "term" return
                for $term in doc($anno:local-authority-file)//tei:taxonomy[ft:query(tei:category, $query)]
                return
                    map {
                        "id": $term/@xml:id/string(),
                        "label": $term/tei:catDesc/string()
                    }
            default return
                ()
    } catch * {
        ()
    }
};

(:~
 : Return the insertion point to which a local authority record should be appended
 : when creating a local copy.
 :)
declare function anno:insert-point($type as xs:string) {
    switch ($type)
        case "place" return
            doc($anno:local-authority-file)//tei:listPlace
        case "organization" return
            doc($anno:local-authority-file)//tei:listOrg
        case "term" return
            doc($anno:local-authority-file)//tei:taxonomy
        default return
            doc($anno:local-authority-file)//tei:listPerson
};

(:~
 : For the given local authority entry, return a sequence of other strings (e.g. alternate names) 
 : which should be used when parsing the text for occurrences.
 :)
declare function anno:local-search-strings($type as xs:string, $entry as element()?) {
    switch($type)
        case "place" return $entry/tei:placeName/string()
        case "organization" return $entry/tei:orgName/string()
        case "term" return $entry/tei:catDesc/string()
        default return $entry/tei:persName/string()
};