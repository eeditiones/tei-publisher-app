xquery version "3.1";


module namespace register = "http://existsolutions.com/app/doi/registration";
import module namespace doi = "http://existsolutions.com/app/doi" at "dalra-api.xql";
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
        doi:create-update-resource($metadata, true())
};

(:
    todo: design a mapping facility that allows to read specific fields for specific incoming documents. Entities
    like e.g. the author can be encoded in TEI in many different ways. It will be hard to provide a all-fits-all
    solution. Best guess: allow some mapping table to be configured per collection that contains XPathes for the
    required properties of the DOI resource file.
:)
declare function register:create-metadata($document,$url,$availability){
    <resource xmlns="http://da-ra.de/schema/kernel-4"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://da-ra.de/schema/kernel-4 http://www.da-ra.de/fileadmin/media/da-ra.de/Technik/4.0/dara.xsd">
        <resourceType>Text</resourceType>
        <titles>
            <title>
                <language>en</language>
                <titleName>{data($document//tei:title[1]),'Anon'}</titleName>
            </title>
        </titles>

        <!-- todo: author needs to be parsed into fore and last name -->


        <creators>
            <creator>
                <person>
                    <firstName>Henning</firstName>
                    <lastName>{data($document//tei:author),'Anon'}</lastName>
                </person>
            </creator>
        </creators>
        
        <dataURLs>
            <dataURL>http://foobar.com/myresource</dataURL>
        </dataURLs>

        <!-- first date in tei:revisionDesc -->
        <publicationDate>
            <date>2020-10-01</date>
        </publicationDate>

        <publisher>
            <institution>
                <institutionName>BBF - Bibliothek für Bildungsgeschichtliche Forschung</institutionName>
                <institutionIDs>
                    <institutionID>
                        <identifierURI>http://d-nb.info/gnd/2008623-4</identifierURI>
                        <identifierSchema>GND</identifierSchema>
                    </institutionID>
                    <institutionID>
                        <identifierURI>http://viaf.org/viaf/126599419</identifierURI>
                        <identifierSchema>VIAF</identifierSchema>
                    </institutionID>
                </institutionIDs>
            </institution>
        </publisher>



        <availability>
            <availabilityType>{$availability}</availabilityType>
        </availability>

    </resource>
};



