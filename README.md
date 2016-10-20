# TEI Processing Model Toolbox

The TEI Processing Model (PM) extends the TEI ODD specification format with a processing model for documents. That way intended processing for all elements can be expressed within the TEI vocubulary itself. It aims at the XML-savvy editor who is familiar with TEI but is not necessarily a developer.

The TEI Processing Model Toolbox for eXist facilitates the integration of the TEI processing model into existing applications, supporting a range of different output media without requiring advanced coding skills. Customising the appearance of the text is all done in TEI by mapping each TEI element to a limited set of well-defined behaviour functions, e.g. “paragraph”, “heading”, “note”, “alternate”, etc. The TEI Processing Model includes a standard mapping, which can be extended by overwriting selected elements. Rendition styles are transparently translated into the different output media types like HTML, XSL-FO, LaTeX, or ePUB. Compared to traditional approaches with XSLT or XQuery, TEI Simple may thus easily save a few thousand lines of code for media specific stylesheets.

![Editing an ODD](doc/EditODD.gif)

## Demo

A demo of the app is available on

http://showcases.exist-db.org/exist/apps/tei-simple/index.html

The library modules are also used by the Early English Books demo which includes more than 30,000 documents:

http://showcases.exist-db.org/exist/apps/eebo/

## Installation

A prebuilt version of the app can be installed from eXist's central app repository. On your eXist installation, open the package manager in the dashboard and select "TEI Simple Processing Model" for installation. Dependencies should be installed automatically.

**Important**: Due to a bug in the 2.2 release, the tei-simple module requires [eXistdb 3.0RC1](https://bintray.com/existdb/releases/exist/3.0.RC1/view/files) or later.

## Documentation

For an overview of the app and library, please refer to my [presentation](http://showcases.exist-db.org/exist/apps/tei-simple/modules/latex.xql?odd=beamer.odd&doc=/doc/presentation.xml). There's also some preliminary [documentation](http://showcases.exist-db.org/exist/apps/tei-simple/doc/documentation.xml?odd=documentation.odd) available.

## Building

For PDF output, you need to enable the Apache FOP extension as follows:

* in extensions/build.properties, set "include.module.xslfo = true"
* rebuild eXist to install the Apache FOP libraries
* edit conf.xml and uncomment the fo module:

```xml
<module uri="http://exist-db.org/xquery/xslfo" class="org.exist.xquery.modules.xslfo.XSLFOModule">
    <parameter name="processorAdapter" value="org.exist.xquery.modules.xslfo.ApacheFopProcessorAdapter"/>
</module>
```

tei-simple-pm ships as a .xar package which can be installed into any eXist instance using the dashboard.

To build tei-simple-pm, clone the repository and call "ant" in the root directory. This will create a .xar inside the build directory.

## License

This software is dual-licensed:

1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
http://creativecommons.org/licenses/by-sa/3.0/

2. http://www.opensource.org/licenses/BSD-2-Clause

All rights reserved. Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of
conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

This software is provided by the copyright holders and contributors "as is" and any
express or implied warranties, including, but not limited to, the implied warranties
of merchantability and fitness for a particular purpose are disclaimed. In no event
shall the copyright holder or contributors be liable for any direct, indirect,
incidental, special, exemplary, or consequential damages (including, but not limited to,
procurement of substitute goods or services; loss of use, data, or profits; or business
interruption) however caused and on any theory of liability, whether in contract,
strict liability, or tort (including negligence or otherwise) arising in any way out
of the use of this software, even if advised of the possibility of such damage.

## References

* official TEI Spec - http://www.tei-c.org/release/doc/tei-p5-doc/en/html/TD.html#TDPM
* Extensions to the Processing Model Specification - http://teipublisher.com/doc/documentation.xml?root=1.4.2.2.10.14&odd=documentation.odd&view=div and following
