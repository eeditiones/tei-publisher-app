xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations/config";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare variable $anno:local-authority-file := $config:data-root || "/register.xml";

declare function anno:annotations($type as xs:string, $properties as map(*), $content as function(*)) {
    switch ($type)
        case "person" return
            <persName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</persName>
        case "place" return
            <placeName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</placeName>
        case "term" return
            <term xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</term>
        case "organisation" return
            <orgName xmlns="http://www.tei-c.org/ns/1.0" ref="{$properties?ref}">{$content()}</orgName>
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
        default return
            <hi rend="annotation-not-found">{$content()}</hi>
};

declare function anno:occurrences($type as xs:string, $key as xs:string) {
    switch ($type)
        case "person" return
            collection($config:data-default)//tei:persName[@ref = $key]
        case "place" return
            collection($config:data-default)//tei:placeName[@ref = $key]
        case "term" return
            collection($config:data-default)//tei:term[@ref = $key]
        case "organisation" return
            collection($config:data-default)//tei:orgName[@ref = $key]
        default return ()
};

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
                <ptr type="geonames" target="{$data?link}"/>
                <ptr type="info" target="{$data?info}"/>
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
        case "organisation" return
            <org xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <orgName type="full">{$data?name}</orgName>
            </org>
        default return
            ()
};

declare function anno:query($type as xs:string, $query as xs:string?) {
    switch ($type)
        case "place" return
            for $place in doc($anno:local-authority-file)//tei:place[ft:query(tei:placeName, $query)]
            return
                map {
                    "id": $place/@xml:id/string(),
                    "label": string-join($place/tei:placeName, ', '),
                    "details": ``[`{$place/tei:note/string()}` - `{$place/tei:country/string()}`, `{$place/tei:region/string()}`]``,
                    "link": $place/tei:ptr/@target/string()
                }
        default return
            ()
};