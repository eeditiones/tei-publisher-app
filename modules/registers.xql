xquery version "3.1";

module namespace rapi="http://teipublisher.com/api/registers";

import module namespace router="http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

(:  
import module namespace annocfg = "http://teipublisher.com/api/annotations/config" at "annotation-config.xqm";
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

