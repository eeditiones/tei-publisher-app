
xquery version "3.1";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-lex-0-web="http://www.tei-c.org/pm/models/lex-0/web/module" at "../transform/lex-0-web-module.xql";
import module namespace pm-lex-0-print="http://www.tei-c.org/pm/models/lex-0/print/module" at "../transform/lex-0-print-module.xql";
import module namespace pm-docx-output-web="http://www.tei-c.org/pm/models/docx-output/web/module" at "../transform/docx-output-web-module.xql";
import module namespace pm-docx-output-print="http://www.tei-c.org/pm/models/docx-output/print/module" at "../transform/docx-output-print-module.xql";
import module namespace pm-docx-output-epub="http://www.tei-c.org/pm/models/docx-output/epub/module" at "../transform/docx-output-epub-module.xql";
import module namespace pm-docx-output-markdown="http://www.tei-c.org/pm/models/docx-output/markdown/module" at "../transform/docx-output-markdown-module.xql";
import module namespace pm-docx-output-docx="http://www.tei-c.org/pm/models/docx-output/docx/module" at "../transform/docx-output-docx-module.xql";
import module namespace pm-docx-output-fo="http://www.tei-c.org/pm/models/docx-output/fo/module" at "../transform/docx-output-fo-module.xql";
import module namespace pm-docbook-web="http://www.tei-c.org/pm/models/docbook/web/module" at "../transform/docbook-web-module.xql";
import module namespace pm-docbook-print="http://www.tei-c.org/pm/models/docbook/print/module" at "../transform/docbook-print-module.xql";
import module namespace pm-docbook-epub="http://www.tei-c.org/pm/models/docbook/epub/module" at "../transform/docbook-epub-module.xql";
import module namespace pm-docbook-fo="http://www.tei-c.org/pm/models/docbook/fo/module" at "../transform/docbook-fo-module.xql";
import module namespace pm-docbook-markdown="http://www.tei-c.org/pm/models/docbook/markdown/module" at "../transform/docbook-markdown-module.xql";
import module namespace pm-docbook-docx="http://www.tei-c.org/pm/models/docbook/docx/module" at "../transform/docbook-docx-module.xql";
import module namespace pm-jats-annotations-web="http://www.tei-c.org/pm/models/jats-annotations/web/module" at "../transform/jats-annotations-web-module.xql";
import module namespace pm-landing-web="http://www.tei-c.org/pm/models/landing/web/module" at "../transform/landing-web-module.xql";
import module namespace pm-vangogh-web="http://www.tei-c.org/pm/models/vangogh/web/module" at "../transform/vangogh-web-module.xql";
import module namespace pm-vangogh-print="http://www.tei-c.org/pm/models/vangogh/print/module" at "../transform/vangogh-print-module.xql";
import module namespace pm-vangogh-epub="http://www.tei-c.org/pm/models/vangogh/epub/module" at "../transform/vangogh-epub-module.xql";
import module namespace pm-vangogh-markdown="http://www.tei-c.org/pm/models/vangogh/markdown/module" at "../transform/vangogh-markdown-module.xql";
import module namespace pm-vangogh-docx="http://www.tei-c.org/pm/models/vangogh/docx/module" at "../transform/vangogh-docx-module.xql";
import module namespace pm-vangogh-fo="http://www.tei-c.org/pm/models/vangogh/fo/module" at "../transform/vangogh-fo-module.xql";
import module namespace pm-osinski-web="http://www.tei-c.org/pm/models/osinski/web/module" at "../transform/osinski-web-module.xql";
import module namespace pm-osinski-print="http://www.tei-c.org/pm/models/osinski/print/module" at "../transform/osinski-print-module.xql";
import module namespace pm-osinski-epub="http://www.tei-c.org/pm/models/osinski/epub/module" at "../transform/osinski-epub-module.xql";
import module namespace pm-osinski-markdown="http://www.tei-c.org/pm/models/osinski/markdown/module" at "../transform/osinski-markdown-module.xql";
import module namespace pm-osinski-docx="http://www.tei-c.org/pm/models/osinski/docx/module" at "../transform/osinski-docx-module.xql";
import module namespace pm-osinski-fo="http://www.tei-c.org/pm/models/osinski/fo/module" at "../transform/osinski-fo-module.xql";
import module namespace pm-jats-web="http://www.tei-c.org/pm/models/jats/web/module" at "../transform/jats-web-module.xql";
import module namespace pm-jats-print="http://www.tei-c.org/pm/models/jats/print/module" at "../transform/jats-print-module.xql";
import module namespace pm-jats-epub="http://www.tei-c.org/pm/models/jats/epub/module" at "../transform/jats-epub-module.xql";
import module namespace pm-jats-markdown="http://www.tei-c.org/pm/models/jats/markdown/module" at "../transform/jats-markdown-module.xql";
import module namespace pm-jats-docx="http://www.tei-c.org/pm/models/jats/docx/module" at "../transform/jats-docx-module.xql";
import module namespace pm-jats-fo="http://www.tei-c.org/pm/models/jats/fo/module" at "../transform/jats-fo-module.xql";
import module namespace pm-docx-tei="http://www.tei-c.org/pm/models/docx/tei/module" at "../transform/docx-tei-module.xql";
import module namespace pm-teipublisher-web="http://www.tei-c.org/pm/models/teipublisher/web/module" at "../transform/teipublisher-web-module.xql";
import module namespace pm-teipublisher-print="http://www.tei-c.org/pm/models/teipublisher/print/module" at "../transform/teipublisher-print-module.xql";
import module namespace pm-teipublisher-epub="http://www.tei-c.org/pm/models/teipublisher/epub/module" at "../transform/teipublisher-epub-module.xql";
import module namespace pm-teipublisher-markdown="http://www.tei-c.org/pm/models/teipublisher/markdown/module" at "../transform/teipublisher-markdown-module.xql";
import module namespace pm-teipublisher-docx="http://www.tei-c.org/pm/models/teipublisher/docx/module" at "../transform/teipublisher-docx-module.xql";
import module namespace pm-teipublisher-fo="http://www.tei-c.org/pm/models/teipublisher/fo/module" at "../transform/teipublisher-fo-module.xql";
import module namespace pm-dta-web="http://www.tei-c.org/pm/models/dta/web/module" at "../transform/dta-web-module.xql";
import module namespace pm-dta-print="http://www.tei-c.org/pm/models/dta/print/module" at "../transform/dta-print-module.xql";
import module namespace pm-dta-epub="http://www.tei-c.org/pm/models/dta/epub/module" at "../transform/dta-epub-module.xql";
import module namespace pm-dta-markdown="http://www.tei-c.org/pm/models/dta/markdown/module" at "../transform/dta-markdown-module.xql";
import module namespace pm-dta-docx="http://www.tei-c.org/pm/models/dta/docx/module" at "../transform/dta-docx-module.xql";
import module namespace pm-dta-fo="http://www.tei-c.org/pm/models/dta/fo/module" at "../transform/dta-fo-module.xql";
import module namespace pm-shakespeare-web="http://www.tei-c.org/pm/models/shakespeare/web/module" at "../transform/shakespeare-web-module.xql";
import module namespace pm-shakespeare-print="http://www.tei-c.org/pm/models/shakespeare/print/module" at "../transform/shakespeare-print-module.xql";
import module namespace pm-shakespeare-epub="http://www.tei-c.org/pm/models/shakespeare/epub/module" at "../transform/shakespeare-epub-module.xql";
import module namespace pm-shakespeare-markdown="http://www.tei-c.org/pm/models/shakespeare/markdown/module" at "../transform/shakespeare-markdown-module.xql";
import module namespace pm-shakespeare-docx="http://www.tei-c.org/pm/models/shakespeare/docx/module" at "../transform/shakespeare-docx-module.xql";
import module namespace pm-shakespeare-fo="http://www.tei-c.org/pm/models/shakespeare/fo/module" at "../transform/shakespeare-fo-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "lex-0.odd" return pm-lex-0-web:transform($xml, $parameters)
case "docx-output.odd" return pm-docx-output-web:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-web:transform($xml, $parameters)
case "jats-annotations.odd" return pm-jats-annotations-web:transform($xml, $parameters)
case "landing.odd" return pm-landing-web:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-web:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-web:transform($xml, $parameters)
case "jats.odd" return pm-jats-web:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-web:transform($xml, $parameters)
case "dta.odd" return pm-dta-web:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-web:transform($xml, $parameters)
    default return pm-teipublisher-web:transform($xml, $parameters)
            

};
            


declare variable $pm-config:print-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "lex-0.odd" return pm-lex-0-print:transform($xml, $parameters)
case "docx-output.odd" return pm-docx-output-print:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-print:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-print:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-print:transform($xml, $parameters)
case "jats.odd" return pm-jats-print:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-print:transform($xml, $parameters)
case "dta.odd" return pm-dta-print:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-print:transform($xml, $parameters)
    default return pm-teipublisher-print:transform($xml, $parameters)
            

};
            


declare variable $pm-config:epub-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx-output.odd" return pm-docx-output-epub:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-epub:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-epub:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-epub:transform($xml, $parameters)
case "jats.odd" return pm-jats-epub:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-epub:transform($xml, $parameters)
case "dta.odd" return pm-dta-epub:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-epub:transform($xml, $parameters)
    default return pm-teipublisher-epub:transform($xml, $parameters)
            

};
            


declare variable $pm-config:markdown-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx-output.odd" return pm-docx-output-markdown:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-markdown:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-markdown:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-markdown:transform($xml, $parameters)
case "jats.odd" return pm-jats-markdown:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-markdown:transform($xml, $parameters)
case "dta.odd" return pm-dta-markdown:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-markdown:transform($xml, $parameters)
    default return pm-teipublisher-markdown:transform($xml, $parameters)
            

};
            


declare variable $pm-config:docx-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx-output.odd" return pm-docx-output-docx:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-docx:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-docx:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-docx:transform($xml, $parameters)
case "jats.odd" return pm-jats-docx:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-docx:transform($xml, $parameters)
case "dta.odd" return pm-dta-docx:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-docx:transform($xml, $parameters)
    default return pm-teipublisher-docx:transform($xml, $parameters)
            

};
            


declare variable $pm-config:fo-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx-output.odd" return pm-docx-output-fo:transform($xml, $parameters)
case "docbook.odd" return pm-docbook-fo:transform($xml, $parameters)
case "vangogh.odd" return pm-vangogh-fo:transform($xml, $parameters)
case "osinski.odd" return pm-osinski-fo:transform($xml, $parameters)
case "jats.odd" return pm-jats-fo:transform($xml, $parameters)
case "teipublisher.odd" return pm-teipublisher-fo:transform($xml, $parameters)
case "dta.odd" return pm-dta-fo:transform($xml, $parameters)
case "shakespeare.odd" return pm-shakespeare-fo:transform($xml, $parameters)
    default return pm-teipublisher-fo:transform($xml, $parameters)
            

};
            


declare variable $pm-config:tei-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
    case "docx.odd" return pm-docx-tei:transform($xml, $parameters)
    default return error(QName("http://www.tei-c.org/tei-simple/pm-config", "error"), "No default ODD found for output mode tei")
            

};
            
    