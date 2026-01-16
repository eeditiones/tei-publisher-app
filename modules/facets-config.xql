module namespace facets-config="http://teipublisher.com/api/facets-config";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function facets-config:get-name($id as xs:string, $type as xs:string) as xs:string {
    let $entity := collection($config:register-root)/id($id)
    return head((
            switch ($type)
                case 'place' return head(($entity//tei:placeName[@type = "main"], $entity//tei:placeName))
                case 'actor' return head(($entity//(tei:persName | tei:orgName)[@type = "main"], $entity//tei:placeName))
                default return "ERR",
             "Unresolvable entity " || $id || " of type " || $type)
        )
};

(:
 : Display configuration for facets to be shown in the sidebar. The facets themselves
 : are configured in the index configuration, collection.xconf.
 :)
declare variable $facets-config:facets := [
    map {
        "dimension": "genre",
        "heading": "facets.genre",
        "max": 10,
        "hierarchical": true()
    },
    map {
        "dimension": "language",
        "heading": "facets.language",
        "source": "api/search/facets/language",
        "max": 5,
        "hierarchical": false(),
        "output": function($label, $language) {
            switch($label)
                case "de" return "German"
                case "es" return "Spanish"
                case "la" return "Latin"
                case "fr" return "French"
                case "en" return "English"
                case "pl" return "Polish"
                case "uk" return "Ukrainian"
                default return $label
        }
    },
    map {
        "dimension": "feature",
        "heading": "facets.feature",
        "source": "api/search/facets/feature",
        "output": function($label) {
            upper-case(substring($label,1,1)) || substring($label, 2)
        },
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "period",
        "heading": "facets.period",
        "max": 15,
        "hierarchical": false()
    },
    map {
        "dimension": "form",
        "heading": "facets.form",
        "max": 15,
        "hierarchical": false()
    }
];