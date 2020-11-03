xquery version "3.1";

import module namespace register = "http://existsolutions.com/app/doi/registration" at 'register-doi.xql';
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:validate($doc) {
    let $grammar := xs:anyURI("/db/apps/tei-publisher/doi/schema/data.xsd")

    let $valid := validation:jing($doc, $grammar)
    return
        if(not($valid))
        then (
            <result file="{util:document-name($doc)}">
            {validation:jing-report($doc, $grammar)}
            </result>
        )
        else 
            <result file="{util:document-name($doc)}">
                {$valid}
            </result>
        
};
let $doc := doc('/db/apps/tei-publisher/doi/data/example/es1903-09-18-002.xml')
return
(:    $doc:)
(:local:validate(register:create-metadata($doc,'Download')):)

register:create-metadata($doc,'Download')