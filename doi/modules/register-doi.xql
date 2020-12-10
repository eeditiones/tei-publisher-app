xquery version "3.1";


module namespace register = "http://existsolutions.com/app/doi/registration";
import module namespace dara = "http://existsolutions.com/app/dara" at "dalra-api.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
    registers a new DOI (http://doi.org) with bare-bones metadata for given TEI-Document.

    Expect for the 'availability' param all values in the metadata are pulled from the incoming
    document.

    @param the document payload
    @param $url - a fully qualified URL (incl. hostname)
    @param $availability - a valid value for the 'availability' Element
:)
declare function register:register-doi-for-document($document, $url, $availability){
    let $metadata := register:create-metadata($document,$url,$availability)
    return
        dara:create-update-resource($metadata, true())
};

(:
    create minimal metadata set. Data are filled in from incomimg TEI document (except for availability).

    Matching of TEI pathes to metadata assume standards of the "Deutsches Textarchiv".

    Note: for a generalized approach a mapping configuration needs to be added to this implementation.
:)
declare function register:create-metadata($document,$url,$availability){

let $fields := map {
    "url": "https://tei-publisher.com",
    "title-lang": "en",
    "title": data(head(($document//tei:titleStmt/tei:title, 'NO_TITLE'))),
    "institution": data(head(($document//tei:editionStmt/tei:respStmt/tei:orgName, 'NO_ORGNAME'))),
    "publication": data(head(($document//tei:publicationStmt/date[@type="publication"],"1970-01-01"))),
    "license": data(head((data($document//tei:header/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p),"NO_LICENSE"))),
    "license-lang": "de"
}

return
    <resource xmlns="http://da-ra.de/schema/kernel-4"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://da-ra.de/schema/kernel-4 http://www.da-ra.de/fileadmin/media/da-ra.de/Technik/4.0/dara.xsd">
        <resourceType>Text</resourceType>
        <titles>
            <title>
                <language>{$fields?title-lang}</language>
                <titleName>{$fields?title}</titleName>
            </title>
        </titles>

        <creators>
            <creator>
                <institution>
                    <institutionName>{$fields?institution}</institutionName>
                </institution>
            </creator>
        </creators>
        
        <dataURLs>
            <dataURL>{$fields?url}</dataURL>
        </dataURLs>

        <publicationDate>
            <date>{$fields?publication}</date>
        </publicationDate>

        <publisher>
            <institution>
                <institutionName>BBF - Bibliothek für Bildungsgeschichtliche Forschung</institutionName>
                <institutionIDs>
                    <institutionID>
                        <identifierURI>http://d-nb.info/gnd/2127361-3</identifierURI>
                        <identifierSchema>GND</identifierSchema>
                    </institutionID>
                    <institutionID>
                        <identifierURI>https://viaf.org/viaf/144277281/</identifierURI>
                        <identifierSchema>VIAF</identifierSchema>
                    </institutionID>
                </institutionIDs>
            </institution>
        </publisher>

        <availability>
            <availabilityType>{$availability}</availabilityType>
        </availability>

        <rights>
            <right>
                <language>{$fields?license-lang}</language>
                <freetext>{$fields?license}</freetext>
            </right>
        </rights>
    </resource>
};



