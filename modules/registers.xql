xquery version "3.1";

module namespace rapi="http://teipublisher.com/api/registers";

import module namespace router="http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace annocfg = "http://teipublisher.com/api/annotations/config" at "annotation-config.xqm";

(:  
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";
import module namespace nav-tei="http://www.tei-c.org/tei-simple/navigation/tei" at "../../navigation-tei.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../../navigation.xql";
import module namespace query="http://www.tei-c.org/tei-simple/query" at "../../query.xql";
import module namespace mapping="http://www.tei-c.org/tei-simple/components/map" at "../../map.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace xslfo="http://exist-db.org/xquery/xslfo" at "java:org.exist.xquery.modules.xslfo.XSLFOModule";
import module namespace epub="http://exist-db.org/xquery/epub" at "../epub.xql";
import module namespace docx="http://existsolutions.com/teipublisher/docx";
import module namespace cutil="http://teipublisher.com/api/cache" at "caching.xql";
:)
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function rapi:entry($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $entry := collection($config:registers-root)/id($id)

    return
      if ($id) then
            if ($entry) then
                <data>{$entry}</data>
            else 
                <data>{collection($config:registers-root)/id('person-default')}</data>
        else
            error($errors:BAD_REQUEST, "No entry id specified")
};


declare function rapi:delete($request as map(*)) {
    let $id := xmldb:decode($request?parameters?id)
    let $type := xmldb:decode($request?parameters?type)
    let $entry := collection($config:registers-root)/id($id)

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

declare function rapi:save($request as map(*)) {
    let $f:= util:log('INFO', 'saving record')

    (: todo, change depending on the form type :)
    let $user := request:get-attribute("teipublisher.com.login.user")
    let $id := xmldb:decode($request?parameters?id)
    let $type := local-name($request?body//tei:person)

    let $data := rapi:prepare-record($request?body//tei:person, $user, $type)

    let $record := rapi:insert-point($type)/id($id)

    return
        if ($record) then
            (: update existing record :)
            let $f:= util:log('INFO', 'found')
            return
                (rapi:replace-entry($record, $data), $data)
        else
                (rapi:add-entry($data, $type), $data)
};

(:~
 : Return the insertion point to which a local authority record should be saved.
 :)
declare function rapi:insert-point($type as xs:string) {
    switch ($type)
        case "place" return
            collection($config:registers-root)/id('pb-places')//tei:listPlace
        case "organization" return
            collection($config:registers-root)/id('pb-organizations')//tei:listOrg
        case "term" return
            doc($annocfg:local-authority-file)//tei:taxonomy
        default return
            collection($config:registers-root)/id('pb-persons')//tei:listPerson
};

declare function rapi:add-entry($record, $type) {
    let $target := rapi:insert-point($type)

    return
        update insert $record into $target
};

declare function rapi:replace-entry($record, $data) {
        update replace $record with $data
};

declare function rapi:prepare-record($node as item()*, $resp, $type) {

    let $id := if ($node/@xml:id='NEW') then rapi:next($type) else $node/@xml:id

    return
      typeswitch($node)
        (: normalize-space for all text nodes :)
        case text()
            return normalize-space($node)
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
        
        (: all the rest pass it through :)
        default 
            return $node

};

declare function rapi:next($type) {
    let $config := $config:registers-map?($type)

    let $all-ids := collection($config:registers-root)/id($config?id)//tei:person[starts-with(@xml:id, $config?prefix)]/substring-after(@xml:id, $config?prefix)
    
    let $last := if (count($all-ids)) then sort($all-ids)[last()] else 1
    let $next :=
            try {
                xs:integer($last) + 1
            } catch * {
                'error_'
            }
    
    return $config?prefix || rapi:pad($next, 6)

};


declare function rapi:pad($value, $len) {
    if (string-length($value) < $len) then rapi:pad('0' || $value, $len)
    else $value
};
