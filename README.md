![TEI Publisher Docker Snapshots](https://github.com/eeditiones/tei-publisher-app/workflows/TEI%20Publisher%20Docker%20Snapshots/badge.svg)

<img src="resources/images/tei-publisher-logo-color.svg" height="128">

TEI Publisher facilitates the integration of the TEI Processing Model into exist-db applications. The TEI Processing Model (PM) extends the TEI ODD specification format with a processing model for documents. That way intended processing for all elements can be expressed within the TEI vocabulary itself. It aims at the XML-savvy editor who is familiar with TEI but is not necessarily a developer.

TEI Publisher supports a range of different output media without requiring advanced coding skills. Customising the appearance of the text is all done in TEI by mapping each TEI element to a limited set of well-defined behaviour functions, e.g. “paragraph”, “heading”, “note”, “alternate”, etc. The TEI Processing Model includes a standard mapping, which can be extended by overwriting selected elements. Rendition styles are transparently translated into the different output media types like HTML, XSL-FO, LaTeX, or ePUB. Compared to traditional approaches with XSLT or XQuery, TEI Publisher may thus easily save a few thousand lines of code for media specific stylesheets.

## Website and Support

A demo and further documentation is available on:

[https://teipublisher.com/](https://teipublisher.com/)

For general questions and discussions, please join the [#community](https://join.slack.com/t/e-editiones/shared_invite/zt-e19jc03q-OFaVni~_lh6emSHen6pswg) room on the e-editiones slack.

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

The following instructions apply to both, TEI Publisher itself as well as apps generated from it. Building needs Java and [Apache Ant](https://ant.apache.org/).

TEI Publisher requires the [pb-components](https://github.com/eeditiones/tei-publisher-components) package, which can either be loaded from an external server (CDN) or imported into the local build. Using the CDN is recommended unless you want to use a cutting edge build of the components or you need TEI Publisher to work without an internet connection.

### Using the CDN for Components

Run Apache `ant` in the cloned directory to get a `.xar` file in `build/`, which can be uploaded into an eXist instance via the dashboard.

### Self-hosted Components

This will include all user-interface components and their dependencies into the created package. In addition to `ant`, you should have `nodejs` and `npm` installed on the machine used for building:

1. check if the path to the npm executable in `build.properties` points to the right location on your machine
2. call `ant xar-local` to build TEI Publisher

Sometimes you may also want to update the `pb-components` library to a newer or custom version. The procedure is as follows:

1. edit the dependencies section of `package.json` to include the desired version of the `pb-components` library
2. edit `modules/config.xqm` and change the variable `$config:webcomponents` to read 'local' instead of a version number. This way, the javascript bundles will be loaded from within the TEI Publisher app instead of a CDN
3. run `ant xar-local` to generate a `.xar`

## License

This software is licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license. If you need a different license: please contact [us](mailto:mail@existsolutions.com) and we'll find an arrangement.

TEI Publisher was initiated and released to the public as free software by <a href="http://existsolutions.com"><img src="http://teipublisher.com/img/existsolutions.svg" width="128"/></a> with contributions from other users. It's development was supported by a wide range of privately and publicly funded projects.

Development is supported and coordinated by [e-editiones](https://e-editiones.org).

![e-editiones logo](resources/images/e-editiones-logo-color-for-light-bg-05.svg)

## Editing Resources

All resources can either be edited live via eXist-db's XML editor eXide or via local development having `ant` installed.

## Development

Following instructions are only relevant for developers who want to contribute to TEI Publisher. Different approaches are possible:

1. use eXide to directly change resources inside the database, then sync them to a local directory where you have checked out the code from gitlab
2. use the Atom or Visual Studio Code editors with the corresponding eXistdb plugin and open a local copy of the TEI Publisher repository as a project. Both editor plugins have a feature to sync local modifications into the database. This is the most convenient and recommended method. Similar workflow is possible in Visual Studio Code.

## Docker 

### Build Docker Image
* execute `docker build -t existdb/teipublisher:6.0.0 .` in your terminal

### Run Docker Image
* execute `docker run --publish 8080:8080 --detach --name tp existdb/teipublisher:6.0.0` in your terminal
* open `localhost:8080` in your browser

### How to run a completely dockerized development environment in vscode

With this setup everything will be living inside docker, so you do not need anything apart from vscode and docker, not even Java or nodejs.

Make sure you have [Visual Studio Code](https://code.visualstudio.com/download) installed.

Make sure you do not have eXist running on 8080. 

1. install “Remote - Containers” extension in vscode. In addition we highly recommend to install the "existdb-vscode" and "vscode-xml" extensions.
1. cmd-shift-p and find “Remote Containers: Clone Repository in Container Volume”
1. confirm “Clone a repository from GitHub in a Container Volume”
1. type “tei-publisher-app” and select “eeditiones/tei-publisher-app”
1. select “Create a unique volume”

The container is now being built, which takes a while as it:

* pulls Java 8, 
* installs eXist 5.2.0,
* clones all dependencies
* and installs everything in the database.

Once it completes, you should see vscode with TEI Publisher directory opened and you can go to http://localhost:8080 to find the dashboard as usual. Once you're done for the moment, choose `Close Remote Connection` from the file menu. This will properly stop the container and eXist. To start again, either use menu `File/Open Recent` and choose the entry ending with `[Dev Container]` or select the *Remote Explorer* tab on the left sidebar, make sure it shows your *Containers* in the top dropdown, and start the one you created before.

**Important**: After you stop the container, give eXist a chance to shut down properly before you restart, so please wait a few seconds.
