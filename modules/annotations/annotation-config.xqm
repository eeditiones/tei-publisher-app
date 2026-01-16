xquery version "3.1";

module namespace anno="http://teipublisher.com/api/annotations/config";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

(:~
 : Name of the attribute to use as reference key for entities
 :)
declare variable $anno:reference-key := 'key';

(:~
 : Return the entity reference key for the given node.
 :)
declare function anno:get-key($node as element()) as xs:string? {
    $node/@*[local-name(.) = $anno:reference-key]
};

(:~
 : Determine the entity type of the given node and return as string.
 :)
declare function anno:entity-type($node as element()) as xs:string? {
    typeswitch($node)
        case element(tei:persName) | element(tei:author) return
            "person"
        case element(tei:placeName) | element(tei:pubPlace) return
            "place"
        case element(tei:term) return
            "term"
        case element(tei:orgName) return
            "organization"
        default return
            ()
};