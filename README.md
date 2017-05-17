# TEI Publisher

The TEI Processing Model (PM) extends the TEI ODD specification format with a processing model for documents. That way intended processing for all elements can be expressed within the TEI vocubulary itself. It aims at the XML-savvy editor who is familiar with TEI but is not necessarily a developer.

TEI Publisher for eXist facilitates the integration of the TEI processing model into existing applications, supporting a range of different output media without requiring advanced coding skills. Customising the appearance of the text is all done in TEI by mapping each TEI element to a limited set of well-defined behaviour functions, e.g. “paragraph”, “heading”, “note”, “alternate”, etc. The TEI Processing Model includes a standard mapping, which can be extended by overwriting selected elements. Rendition styles are transparently translated into the different output media types like HTML, XSL-FO, LaTeX, or ePUB. Compared to traditional approaches with XSLT or XQuery, TEI Publisher may thus easily save a few thousand lines of code for media specific stylesheets.

![Editing an ODD](data/doc/EditODD.gif)

## Demo

A demo of the app is available on

https://teipublisher.com/

## Installation

A prebuilt version of the app can be installed from eXist's central app repository. On your eXist installation, open the package manager in the dashboard and select "TEI Simple Processing Model" for installation. Dependencies should be installed automatically.

**Important**: Due to a bug in the 2.2 release, the tei-simple module requires [eXistdb 3.0RC1](https://bintray.com/existdb/releases/exist/3.0.RC1/view/files) or later.

## Documentation

For an overview of the app and library, please refer to the [documentation](http://teipublisher.com/exist/apps/tei-publisher/doc/documentation.xml) available.

## Building

Run Apache ant in the cloned directory to get a .xar file in build/, which can be uploaded
via the dashboard.

## License

This software is licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license. If you need a different license: please contact [us](mailto:mail@existsolutions.com) and we'll find an arrangement.

## References

* official TEI Spec - http://www.tei-c.org/release/doc/tei-p5-doc/en/html/TD.html#TDPM
* Extensions to the Processing Model Specification - http://teipublisher.com/doc/documentation.xml?root=1.4.2.2.10.14&odd=documentation.odd&view=div and following


## Editing Resources

All resources can either be edited live via eXistdb's XML editor eXide or via local development having `node` and `ant`installed.

## Development

### Prerequisites
* Install npm: [https://www.npmjs.com/get-npm](https://www.npmjs.com/get-npm)


### Install global node packages for the front-end and automation tasks

Install node modules by running

    npm install -g gulp


### Build

`gulp build` builds the styles by processing less into minified css with sourcemaps.

`gulp deploy` sends files (and built styles) to the local existDB

`gulp watch` will upload files to the local existDB whenever a source file changes.

**NOTE:** For the deploy and watch task you may have to edit the DB credentials in `gulpfile.js`.
