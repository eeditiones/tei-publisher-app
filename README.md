# TEI Publisher

TEI Publisher facilitates the integration of the TEI Processing Model into exist-db applications. The TEI Processing Model (PM) extends the TEI ODD specification format with a processing model for documents. That way intended processing for all elements can be expressed within the TEI vocabulary itself. It aims at the XML-savvy editor who is familiar with TEI but is not necessarily a developer.

TEI Publisher supports a range of different output media without requiring advanced coding skills. Customising the appearance of the text is all done in TEI by mapping each TEI element to a limited set of well-defined behaviour functions, e.g. “paragraph”, “heading”, “note”, “alternate”, etc. The TEI Processing Model includes a standard mapping, which can be extended by overwriting selected elements. Rendition styles are transparently translated into the different output media types like HTML, XSL-FO, LaTeX, or ePUB. Compared to traditional approaches with XSLT or XQuery, TEI Publisher may thus easily save a few thousand lines of code for media specific stylesheets.

![Editing an ODD](data/doc/EditODD.gif)

## Website and Support

A demo and further documentation is available on:

[https://teipublisher.com/](https://teipublisher.com/)

For general questions and discussions, please use our public hipchat room:

<a href="https://www.hipchat.com/gROkvVTMA">
<img src="https://www.hipchat.com/img/design_align/hipchat-logo-small.svg" width="128"/>
</a>

If you need professional support or consulting, feel free to send your inquiry to [eXist Solutions](mailto:mail@existsolutions.com).

## Installation

A prebuilt version of the app can be installed from exist-db's central app repository. On your exist-db installation, open the package manager in the dashboard and select "TEI Publisher" for installation. This should automatically install dependencies such as the "TEI Publisher: Processing Model Libraries."

**Important**: Due to a bug in the 2.2 release, the tei-simple module requires [eXist-db 3.0RC1](https://bintray.com/existdb/releases/exist/3.0.RC1/view/files) or later.

## Documentation

For an overview of the app and library, please refer to the [documentation](http://teipublisher.com/exist/apps/tei-publisher/doc/documentation.xml) available.

## Building

Run Apache ant in the cloned directory to get a .xar file in build/, which can be uploaded
via the dashboard.

## License

This software is licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license. If you need a different license: please contact [us](mailto:mail@existsolutions.com) and we'll find an arrangement.

TEI Publisher is brought to you by <a href="http://existsolutions.com"><img src="http://teipublisher.com/img/existsolutions.svg" width="128"/></a> with contributions from other users. It's development was supported by a wide range of privately and publicly funded projects.

## Editing Resources

All resources can either be edited live via eXist-db's XML editor eXide or via local development having `node` and `ant`installed.

## Development

### Prerequisites
*   Install npm: [https://www.npmjs.com/get-npm](https://www.npmjs.com/get-npm)


### Install global node packages for the front-end and automation tasks

Install node modules by running

    npm install -g gulp


### Build

`gulp build` builds the styles by processing less into minified css with sourcemaps.

`gulp deploy` sends files (and built styles) to the local exist-db

`gulp watch` will upload files to the local exist-db instance whenever a source file changes.

**NOTE:** For the deploy and watch task you may have to edit the DB credentials in `gulpfile.js`.

### Testing
`gulp test` currently contains just a placeholder message, while integrating the test suite is work in progress.

Please follow these instructions [here](http://gitlab.existsolutions.com/tei-publisher/tei-publisher-app/tree/master/webtest), for running the test-suite.
