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
    <resource xmlns="http://da-ra.de/schema/kernel-4"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://da-ra.de/schema/kernel-4 http://www.da-ra.de/fileadmin/media/da-ra.de/Technik/4.0/dara.xsd">
        <resourceType>Text</resourceType>
        <titles>
            <title>
                <language>en</language>
                <titleName>{data($document//tei:title[1]),'NO_TITLE'}</titleName>
            </title>
        </titles>

        <creators>
            <creator>
                <institution>
                    <institutionName>{data($document//tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:respStmt/tei:orgName),'NO_ORGNAME'}</institutionName>
                </institution>
            </creator>
        </creators>
        
        <dataURLs>
            <dataURL>https://tei-publisher.com</dataURL>
        </dataURLs>

        <publicationDate>
            <date>{data($document//tei:publicationStmt/date[@type="publication"]),"1970-01-01"}</date>
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
                <language>de</language>
                <freetext>{data($document//tei:header/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p),"NO_LICENSE"}</freetext>
            </right>
        </rights>

    </resource>
};



