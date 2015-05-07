xquery version "3.0";

module namespace odt = "http://exist-db.org/xquery/odt";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util" at "/db/apps/tei-simple/content/util.xql";
import module namespace odtf="http://www.tei-c.org/tei-simple/xquery/functions/odt" at "/db/apps/tei-simple/content/odt-functions.xql";

declare function odt:generate($config as map(*), $root as element(), $id as xs:string) {
    odt:mimetype-entry(),
    odt:manifest-entry(),
    odt:content-entry($config, $root),
    odt:styles-entry($config)
};

declare function odt:mimetype-entry() {
    <entry name="mimetype" type="text" method="store">application/vnd.oasis.opendocument.text</entry>
};

declare function odt:manifest-entry() {
    <entry name="META-INF/manifest.xml" type="xml">
        <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
            <manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.text"
                manifest:full-path="/"/>
            <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
            <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/>
        </manifest:manifest>
    </entry>
};

declare function odt:content-entry($config as map(*), $root as element()) {
    <entry name="content.xml" type="xml">
        <office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
            xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
            xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
            xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
            xmlns:math="http://www.w3.org/1998/Math/MathML"
            xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
            xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
            xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer"
            xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
            xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" office:version="1.2">
            <office:body>
                <office:text>
                    <text:p text:style-name="Standard">This is a paragraph.</text:p>
                    {
                        pmu:process($config?odd, $root, $config?output-root, "odt", "../resources/odd", $config?modules)
                    }
                </office:text>
            </office:body>
        </office:document-content>
    </entry>
};

declare function odt:styles-entry($config as map(*)) {
    <entry name="styles.xml" type="xml">
        <office:document-styles xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
            xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
            xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
            xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
            xmlns:math="http://www.w3.org/1998/Math/MathML"
            xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
            xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
            xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer"
            xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
            office:version="1.2">
            <office:styles>
            {
                odtf:styles($config)
            }
            </office:styles>
        </office:document-styles>
    </entry>
};