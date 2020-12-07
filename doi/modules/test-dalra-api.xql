xquery version "3.1";

import module namespace doi = "http://existsolutions.com/app/doi" at "dalra-api.xql";

declare function local:get-resource(){
    let $doi := "10.17889/10.mdsdoc.4.0"
    (: let $doi := "10"  :)
    return
        doi:get-resource-identifier($doi)
};

declare function local:post-resource() {
     let $doc := doc("/db/apps/tei-publisher/doi/data/example/10.4232-10.mdsdoc.4.0.xml")
     return 
         doi:create-update-resource($doc, true())
};

declare function local:validate() {
    let $grammar := xs:anyURI("/db/apps/doi/schema/data.xsd")
    let $doc-path := "/db/apps/doi/data/example"
    return
        for $resource in xmldb:get-child-resources($doc-path)
            return 
                let $doc := doc($doc-path || "/" || $resource)
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

declare function local:validate-dois() {
  let $regex := "^10.\d{4,9}/[-._;()/:a-zA-Z0-9]+"
  let $dois := ("10.17889/10.mdsdoc.4.0", "10.1093/ajae/aaq063", "10.1371/journal.pgen.1001111")
  return
      for $doi in $dois 
        return
            element entry {
                attribute doi {$doi}, 
                attribute valid { matches($doi, $regex) }
            }
};

(:   XSD Validation :) 
(: <validate>{local:validate()}</validate> :) 

(: DOI API get-resource-identifier :)
(: local:get-resource() :)

(: DOI API post resource :)
local:post-resource()

(: Validate DOI regex :)
(: <dois>{local:validate-dois()}</dois> :) 


