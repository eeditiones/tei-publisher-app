# TEI Publisher

TEI Publisher facilitates the integration of the TEI Processing Model into exist-db applications. The TEI Processing Model (PM) extends the TEI ODD specification format with a processing model for documents. That way intended processing for all elements can be expressed within the TEI vocabulary itself. It aims at the XML-savvy editor who is familiar with TEI but is not necessarily a developer.

TEI Publisher supports a range of different output media without requiring advanced coding skills. Customising the appearance of the text is all done in TEI by mapping each TEI element to a limited set of well-defined behaviour functions, e.g. “paragraph”, “heading”, “note”, “alternate”, etc. The TEI Processing Model includes a standard mapping, which can be extended by overwriting selected elements. Rendition styles are transparently translated into the different output media types like HTML, XSL-FO, LaTeX, or ePUB. Compared to traditional approaches with XSLT or XQuery, TEI Publisher may thus easily save a few thousand lines of code for media specific stylesheets.

## Website and Support

A demo and further documentation is available on:

[https://teipublisher.com/](https://teipublisher.com/)

For general questions and discussions, please join the [#teipublisher](https://join.slack.com/t/exist-db/shared_invite/enQtNjQ4MzUyNTE4MDY3LTUwZDk5ODBhYjIwMzgyNGIyOGVlZTdjODY2ZGRmZGFhMDM2YjUyZmQ2NmZjMGQyNzE3MmM0ZGRlY2E2ZmM2MjM) room on the eXistdb slack.

If you need professional support or consulting, feel free to send your inquiry to [eXist Solutions](mailto:mail@existsolutions.com).

## Installation

A prebuilt version of the app can be installed from exist-db's central app repository. On your exist-db installation, open the package manager in the dashboard and select "TEI Publisher" for installation. This should automatically install dependencies such as the "TEI Publisher: Processing Model Libraries."

**Important**: TEI Publisher from version 5.0.0 requires [eXist-db 5.0.0](https://bintray.com/existdb/releases/exist/5.0.0/view/files) or later.

## Documentation

For an overview of the app and library, please refer to the [documentation](http://teipublisher.com/exist/apps/tei-publisher/doc/documentation.xml) available.

## Localization

Please use our Crowdin space to help expand and improve localization

[![Crowdin](https://badges.crowdin.net/tei-publisher/localized.svg)](https://crowdin.com/project/tei-publisher)

## Building

TEI Publisher requires the [pb-components](https://gitlab.existsolutions.com/tei-publisher/pb-components) package, which can either be loaded from an external server (CDN) or imported into the local build. If you intend to contribute to TEI Publisher development, you likely want the latter option. For just using TEI Publisher, the first is sufficient.

### For Users

Run Apache `ant` in the cloned directory to get a `.xar` file in `build/`, which can be uploaded into an eXist instance via the dashboard.

### For Developers

1. edit the dependencies section of `package.json` to include the desired version of the `pb-components` library
1. run `npm install` to install dependencies
2. edit `modules/config.xqm` and change the variable `$config:webcomponents` to read 'local' instead of a version number. This way, the javascript bundles will be loaded from within the TEI Publisher app instead of a CDN
3. run Apache `ant xar-local` to generate a .xar

## License

This software is licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license. If you need a different license: please contact [us](mailto:mail@existsolutions.com) and we'll find an arrangement.

TEI Publisher is brought to you by <a href="http://existsolutions.com"><img src="http://teipublisher.com/img/existsolutions.svg" width="128"/></a> with contributions from other users. It's development was supported by a wide range of privately and publicly funded projects.

## Editing Resources

All resources can either be edited live via eXist-db's XML editor eXide or via local development having `node` and `ant` installed.

## Development

Following instructions are only relevant for developers who want to contribute to TEI Publisher. Different approaches are possible:

1. use eXide to directly change resources inside the database, then sync them to a local directory where you have checked out the code from gitlab
2. use the Atom editor with the eXistdb package and open a local copy of the TEI Publisher repository as a project in Atom. Atom will make sure to sync your local modifications into the database. This is the most convenient and recommended method. Similar workflow is possible in Visual Studio Code.

### Web Components Testing

Described in a separate [README.md inside the `webtest` directory](webtest/README.md).
