xquery version "3.1";

module namespace nlp="http://teipublisher.com/api/nlp/config";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Named entity recognition: endpoint of the python API
 :)
declare variable $nlp:api-endpoint := 
    (util:system-property("teipublisher.ner-endpoint"), "http://localhost:8001")[1];

(:~
 : List of named entity types to be used for training, see nlp:entity-type below
 :)
declare variable $nlp:entities := ("PER", "LOC", "ORG");

(:~
 : Defines which TEI elements should be mapped to which named entity type.
 : This is in particular used for training new models. Only elements mapped
 : below will be considered as training entities.
 :)
declare function nlp:entity-type($node as element()) {
    typeswitch($node)
        (: case element(tei:orgName) return
            "ORG" :)
        case element(tei:persName) | element(tei:author) return
            "PER"
        case element(tei:placeName) | element(tei:pubPlace) return
            "LOC"
        default return
            ()
};

(:~
 : Returns the top-level text blocks which should be used as text
 : fragments for training.
 :)
declare function nlp:blocks($root as element(), $footnotes as xs:boolean?) {
    if ($footnotes) then
        $root//tei:note
    else
        $root/(descendant::tei:p|descendant::tei:head|descendant::tei:opener|descendant::tei:closer)
};