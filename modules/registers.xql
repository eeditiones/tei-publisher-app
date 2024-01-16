xquery version "3.1";

module namespace rapi="http://teipublisher.com/api/registers";

import module namespace router="http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace annocfg = "http://teipublisher.com/api/annotations/config" at "annotation-config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Resolve register entry by id and type and return the record for use in the editing form
 : If a record doesn't exist, use the default record template for a given register type
 :)
declare function rapi:entry($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $entry := collection($config:register-root)/id($id)
    let $type := xmldb:decode($request?parameters?type)

    return
      if ($id) then
            if ($entry) then
                $entry
            else
                let $entry-template := $config:register-map?($type)?default
                return
                    collection($config:register-root)/id($entry-template)/child::*
        else
            error($errors:BAD_REQUEST, "No " || $type || " entry id specified")
};


declare function rapi:delete($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $type := xmldb:decode($request?parameters?type)
    let $entry := collection($config:register-root)/id($id)

    return
      if ($entry) then
            (: let $del := xmldb:remove(util:collection-name($doc), util:document-name($doc)) :)
            let $foo := 'bar'

            return (
                session:set-attribute($config:session-prefix || ".works", ()),
                router:response(204, 'Document deleted')
            )
        else
            error($errors:NOT_FOUND, "Entry for " || $type || ": " || $id || " not found")
};

(:~
 : Save register entry coming from the editing form
 : If a record exists with this id it is updated, otherwise a new one is created
:)
declare function rapi:save($request as map(*)) {

    let $user := request:get-attribute("teipublisher.com.login.user")
    let $body := $request?body/*[1]

    let $type := local-name($body)
    let $type := if ($type = 'org') then "organization" else $type
    let $id := ($body/@xml:id, $request?parameters?id)[1]

    let $data := rapi:prepare-record($body, $user, $type)
    let $record := rapi:insert-point($type)/id($id)

    return
        if ($record) then
            (: update existing record :)
                (rapi:replace-entry($record, $data), 
                    $data,
                    map {"status": "updated"})
        else
                (rapi:add-entry($data, $type), 
                    $data,
                    map {"status": "created"})
};

declare function rapi:add-entry($record, $type) {
    let $target := rapi:insert-point($type)
    return
        update insert $record into $target
};

declare function rapi:replace-entry($record, $data) {
        update replace $record with $data
};

(:~
 : Return the insertion point to which a local authority record should be saved.
 :)
declare function rapi:insert-point($type as xs:string) {
    let $root := $config:register-map?($type)?id
    return 
    switch ($type)
        case "place" return
            collection($config:register-root)/id($root)//tei:listPlace
        case "organization" return
            collection($config:register-root)/id($root)//tei:listOrg
        case "term" return
            collection($config:register-root)/id($root)//tei:taxonomy
        default return
            collection($config:register-root)/id($root)//tei:listPerson
};

(: Adjust content of a register entry coming from the editing form
 : if xml:id is a new entry placeholder, find the next available id
 : add resp and when attributes 
 : all the rest is just passed
 :)
declare function rapi:prepare-record($node as item()*, $resp, $type) {
    let $new := $type || '-NEW'

    let $id := if ($node/@xml:id=$new) then rapi:next($type) else $node/@xml:id

    return
      typeswitch($node)
        case element(tei:person) 
            return
                element {node-name($node)} {
                (: copy attributes :)
                for $att in $node/@* except ($node/@xml:id, $node/@resp, $node/@when)
                   return
                      $att
                ,
                attribute xml:id {$id}
                ,
                attribute when {format-date(current-date(), '[Y]-[M,2]-[D,2]')}
                ,
                attribute resp {$resp}
                ,
                for $child in $node/node()
                   return $child
              }
        case element(tei:place) 
            return
                element {node-name($node)} {
                (: copy attributes :)
                for $att in $node/@* except ($node/@xml:id, $node/@resp, $node/@when)
                   return
                      $att
                ,
                attribute xml:id {$id}
                ,
                attribute when {format-date(current-date(), '[Y]-[M,2]-[D,2]')}
                ,
                attribute resp {$resp}
                ,
                for $child in $node/node()
                   return $child
              }
        (: all the rest pass it through :)
        default 
            return $node

};

(:~ 
: Determine next available id starting with a prefix chosen for a register type 
: prefixes for each type are specified in $config:register-map

: Algorithm assumes the trailing part of existing ids to be an integer, so it can use the next number 
: Numbers are padded with leading zeros
:)
declare function rapi:next($type) {
    let $config := $config:register-map?($type)

    let $all-ids := 
    switch ($type)
        case 'place'
            return collection($config:register-root)/id($config?id)//tei:place[starts-with(@xml:id, $config?prefix)]/substring-after(@xml:id, $config?prefix)
        default 
            return collection($config:register-root)/id($config?id)//tei:person[starts-with(@xml:id, $config?prefix)]/substring-after(@xml:id, $config?prefix)
    
    let $last := if (count($all-ids)) then sort($all-ids)[last()] else 1
    let $next :=
            try {
                xs:integer($last) + 1
            } catch * {
                '_error'
            }
    
    return $config?prefix || rapi:pad($next, 6)

};

declare function rapi:pad($value, $len) {
    if (string-length($value) < $len) then 
        rapi:pad('0' || $value, $len)
    else 
        $value
};


declare function rapi:query-register($request as map(*)) {
    let $type := $request?parameters?type
    let $query := $request?parameters?query
    return
        array {
            rapi:query($type, $query)
        }
};

(:~
 : Query the local register for existing authority entries matching the given type and query string. 
 :)
declare function rapi:query($type as xs:string, $query as xs:string?) {
    try {
        switch ($type)
            case "place" return
                for $place in collection($config:register-root)//tei:place[ft:query(tei:placeName, $query)]
                return
                    map {
                        "id": $place/@xml:id/string(),
                        "label": $place/tei:placeName[@type="main"]/string(),
                        "details": ``[`{$place/tei:note/string()}` - `{$place/tei:country/string()}`, `{$place/tei:region/string()}`]``,
                        "link": $place/tei:ptr/@target/string()
                    }
            case "person" return
                for $person in collection($config:register-root)//tei:person[ft:query(tei:persName, $query)]
                let $birth := $person/tei:birth/tei:date/@when
                let $death := $person/tei:death/tei:date/@when
                let $dates := 
                    if ($birth) then
                        string-join(($birth, $death), " – ")
                    else
                        ()
                return
                    map {
                        "id": $person/@xml:id/string(),
                        "label": $person/tei:persName[@type="main"]/string(),
                        "details": ``[`{$dates}`; `{$person/tei:note/string()}`]``,
                        "link": $person/tei:ptr/@target/string()
                    }
            case "organization" return
                for $org in collection($config:register-root)//tei:org[ft:query(tei:orgName, $query)]
                return
                    map {
                        "id": $org/@xml:id/string(),
                        "label": $org/tei:orgName[@type="main"]/string(),
                        "details": $org/tei:note/string(),
                        "link": $org/tei:ptr/@target/string()
                    }
            case "term" return
                for $term in collection($config:register-root)//tei:taxonomy[ft:query(tei:category, $query)]
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
 : Create a local copy of an external authority record (like GND) based on the given type, id and data
 : passed in by the client.

 Data available in $data parameter is governed by the authority connector, see e.g. gnd.js in tei-publisher-components
 :)
declare function rapi:create-record($type as xs:string, $id as xs:string, $data as map(*)) {
    switch ($type)
        case "place" return
            <place xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$data?fcl}.{$data?fcode}">
                <placeName type="main">{$data?name}</placeName>
                <placeName type="sort">{$data?name}</placeName>
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
                <note></note>
                <ptr type="geonames" target="{$data?links?1}"/>
                {
                    array:subarray($data?links, 2) => array:for-each(function ($link) {
                        <ptr xmlns="http://www.tei-c.org/ns/1.0" type="info" target="{$link}"/>
                    })
                }
            </place>
        case "person" return
            <person xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <persName type="main">{$data?name}</persName>
                <persName type="sort">{$data?name}</persName>
                {rapi:normalize-gender($data?gender?*)}
                {
                    if (exists($data?birth)) then
                        <birth>
                            <date when="{$data?birth}"/>
                            {
                                rapi:process-array($data?placeOfBirth, function($item) {
                                    <placeName xmlns="http://www.tei-c.org/ns/1.0" ref="{$item?id}">{$item?label}</placeName>                       
                                })
                            }
                        </birth>
                    else
                        (),
                    if (exists($data?death)) then
                        <death>
                            <date when="{$data?death}"/>
                            {
                                rapi:process-array($data?placeOfDeath, function($item) {
                                    <placeName xmlns="http://www.tei-c.org/ns/1.0" ref="{$item?id}">{$item?label}</placeName>                       
                                })
                            }
                        </death>
                    else
                        ()
                }
                <note type="bio">{$data?note}</note>
                {
                    if (exists($data?professionOrOccupation)) then
                        for $prof in $data?professionOrOccupation?*
                        return
                            <occupation ref="{$prof?id}">{$prof?label}</occupation>
                    else
                        ()
                }
            </person>
        case "organization" return
            <org xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <orgName type="main">{$data?name}</orgName>
                <orgName type="sort">{$data?name}</orgName>
                <note>{$data?note}</note>
            </org>
        case "term" return
            <category xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}">
                <catDesc>{$data?name}</catDesc>
            </category>
        default return
            ()
};

declare %private function rapi:process-array($arrayOrAtomic, $callback as function(*)) {
    typeswitch($arrayOrAtomic)
        case array(*) return
            array:for-each($arrayOrAtomic, $callback)
        default return
            for $item in $arrayOrAtomic
            return
                $callback($item)
};

(: normalize GND gender values for common cases :)
declare function rapi:normalize-gender($values) {
    for $gender in $values
        return
            switch ($gender?id)
                case "https://d-nb.info/standards/vocab/gnd/gender#male"
                    return 
                        <gender value="M" xmlns="http://www.tei-c.org/ns/1.0">male</gender>
                case "https://d-nb.info/standards/vocab/gnd/gender#female"
                    return 
                        <gender value="F" xmlns="http://www.tei-c.org/ns/1.0">female</gender>
                case "https://d-nb.info/standards/vocab/gnd/gender#notKnown"
                    return 
                        <gender value="U" xmlns="http://www.tei-c.org/ns/1.0">unknown</gender>
                default
                    return 
                        <gender value="{$gender?id}" xmlns="http://www.tei-c.org/ns/1.0">{$gender?label}</gender>
};
(:~
 : For the given local authority entry, return a sequence of other strings (e.g. alternate names) 
 : which should be used when parsing the text for occurrences.

 :)
declare function rapi:local-search-strings($type as xs:string, $entry as element()?) {
    switch($type)
        case "place" return $entry/tei:placeName/string()
        case "organization" return $entry/tei:orgName/string()
        case "term" return $entry/tei:catDesc/string()
        default return $entry/tei:persName/string()
};


(:~
 : Save a local copy of an authority entry - if it has not been stored already -
 : based on the information provided by the client.
 :
 : Dispatches the actual record creation to rapi:create-record.
 :)
declare function rapi:save-local-copy($request as map(*)) {
    let $data := $request?body
    let $type := $request?parameters?type
    let $id := xmldb:decode($request?parameters?id)
    let $record := collection($config:register-root)/id($id)
    return
        if ($record) then
            map {
                "status": "found"
            }
        else
            let $record := rapi:create-record($type, $id, $data)
            let $target := rapi:insert-point($type)
            return 
                if (sm:has-access(xs:anyURI(document-uri(root($target))), "w")) then
                (
                    update insert $record into $target,
                    map {
                        "status": "updated"
                    }
                ) else
                    error($errors:FORBIDDEN, "Permission denied")
};

(:~ 
 : Search for an authority entry in the local register.
:)
declare function rapi:register-entry($request as map(*)) {
    let $type := $request?parameters?type
    let $id := $request?parameters?id
    let $format := $request?parameters?format
    let $entry := collection($config:register-root)/id($id)
    return
        if ($entry) then
            switch ($format)
                case "xml" return
                    router:response(200, "application/xml", $entry)
                default return
                    let $strings := rapi:local-search-strings($type, $entry)
                    return
                        map {
                            "id": $entry/@xml:id/string(),
                            "strings": array { $strings },
                            "details": <div>{$pm-config:web-transform($entry, map {}, "annotations.odd")}</div>
                        }
        else
            error($errors:NOT_FOUND, "Entry for " || $id || " not found")
};

declare function rapi:form-template($request as map(*)) {
    collection($config:register-forms)/id($request?parameters?id)/child::*
};