(:~
    A module for generating an EPUB file out of a TEI document.

    Largely based on code written by Joe Wicentowski.

    @version 0.1

    @see http://en.wikipedia.org/wiki/EPUB
    @see http://www.ibm.com/developerworks/edu/x-dw-x-epubtut.html
    @see http://code.google.com/p/epubcheck/
:)

xquery version "3.1";

module namespace epub = "http://exist-db.org/xquery/epub";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace counter="http://exist-db.org/xquery/counter" at "java:org.exist.xquery.modules.counter.CounterModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace ep="http://www.idpf.org/2007/ops";

(:~
    Main function of the EPUB module for assembling EPUB files:
    Takes the elements required for an EPUB document (wrapped in <entry> elements),
    and uses the compression:zip() function to returns a complete EPUB document.

    @param $title the dc:title of the EPUB
    @param $creator the dc:creator of the EPUB
    @param $text the tei:text element for the file, which contains the divs to be processed into the EPUB
    @param $urn the urn to use in the NCX file
    @param $css css stylesheet text to embed
    @param $filename the name of the EPUB file, sans file extension
    @return serialized EPUB file

    @see http://demo.exist-db.org/exist/functions/compression/zip
:)
declare function epub:generate-epub($config as map(*), $doc, $css, $filename) {
    let $docConfig := map:merge((tpu:parse-pi(root($doc), "div"), map { "view": "div" }))
    let $config := map:merge(($config, map { "docConfig": $docConfig }, map { "type": $docConfig?type }))
    let $xhtml := epub:body-xhtml-entries(root($doc), $config)
    let $entries :=
        (
            epub:mimetype-entry(),
            epub:container-entry(),
            epub:content-opf-entry($config, $doc, $xhtml),
            epub:title-xhtml-entry($config?metadata?language, $doc, $config),
            epub:images-entry($doc, $xhtml),
            epub:stylesheet-entry($css),
            epub:toc-ncx-entry($config, $doc),
            epub:nav-entry($config, $doc),
            epub:fonts-entry($config),
            $xhtml
        )
    return
        $entries
};

(:~
    Helper function, returns the mimetype entry.
    Note that the EPUB specification requires that the mimetype file be uncompressed.
    We can ensure the mimetype file is uncompressed by passing compression:zip() an entry element
    with a method attribute of "store".

    @return the mimetype entry
:)
declare function epub:mimetype-entry() {
    <entry name="mimetype" type="text" method="store">application/epub+zip</entry>
};

declare function epub:fonts-entry($config as map(*)) {
    for $font in $config?fonts?*
    let $name := replace($font, "^.*/([^/]+)$", "$1")
    return
        <entry name="OEBPS/Fonts/{$name}" type="binary">{util:binary-doc($font)}</entry>
};

(:~
    Helper function, returns the META-INF/container.xml entry.

    @return the META-INF/container.xml entry
:)
declare function epub:container-entry() {
    let $container :=
        <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
            <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
        </container>
    return
        <entry name="META-INF/container.xml" type="xml">{$container}</entry>
};

(:~
    Helper function, returns the OEBPS/content.opf entry.

    @param $title the dc:title of the EPUB
    @param $creator the dc:creator of the EPUB
    @param $text the tei:text element for the file, which contains the divs to be processed into the EPUB
    @return the OEBPS/content.opf entry
:)
declare function epub:content-opf-entry($config as map(*), $text, $xhtml as element()*) {
    let $entries :=
        for $entry in $xhtml
        let $id := replace($entry/@name, '^OEBPS/(.*)\.xhtml$', '$1')
        return
            <item xmlns="http://www.idpf.org/2007/opf"
                id="{$id}" href="{$id}.xhtml" media-type="application/xhtml+xml"/>
    let $refs :=
        for $entry in $xhtml
        let $id := replace($entry/@name, '^OEBPS/(.*)\.xhtml$', '$1')
        return
            <itemref xmlns="http://www.idpf.org/2007/opf" idref="{$id}"/>
    let $content-opf :=
        <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="3.0">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                <dc:title>{$config?metadata?title}</dc:title>
                <dc:creator>{$config?metadata?creator}</dc:creator>
                <dc:identifier id="bookid">{$config?metadata?urn}</dc:identifier>
                <dc:language>{$config?metadata?language}</dc:language>
                <meta property="dcterms:modified">{current-dateTime()}</meta>
            </metadata>
            <manifest>
                <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
                <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
                <item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>
                {
                    $entries
                }
                <item id="css" href="stylesheet.css" media-type="text/css"/>
                {
                for $img in distinct-values($xhtml//*:img/@src)
                let $suffix := replace($img, "^.*\.([^\.]+)$", "$1")
                let $media-type :=
                    switch ($suffix)
                        case "jpg" return "image/jpeg"
                        case "tif" return "image/tiff"
                        default return "image/" || $suffix
                return
                    <item id="{$img}" href="{$img}" media-type="{$media-type}"/>
                }
                {
                    for $font in $config?fonts?*
                    let $name := replace($font, "^.*/([^/]+)$", "$1")
                    return
                        <item id="{$name}" href="Fonts/{$name}" media-type="application/x-font-truetype"/>
                }
            </manifest>
            <spine toc="ncx">
                <itemref idref="title"/>
                {
                    $refs
                }
            </spine>
        </package>
    return
        <entry name="OEBPS/content.opf" type="xml">{$content-opf}</entry>
};

declare function epub:images-entry($doc, $entries as element()*) {
    let $root := util:collection-name($doc)
    for $relPath in distinct-values($entries//*:img/@src)
    let $path :=
        if ($config:epub-images-path) then
            $config:epub-images-path || $relPath
        else
            $root || "/" || $relPath
    return
        if (util:binary-doc-available($path)) then
            <entry name="OEBPS/{$relPath}" type="binary">{util:binary-doc($path)}</entry>
        else
            ()
};

(:~
    Helper function, creates the OEBPS/title.html file.

    @param $volume the volume's ID
    @return the entry for the OEBPS/title.html file
:)
declare function epub:title-xhtml-entry($language, $doc, $config) {
    let $title := 'Title page'
    let $body := epub:title-xhtml-body(nav:get-header($config?docConfig, $doc), $config)
    let $title-xhtml := epub:assemble-xhtml($title, $language, $body)
    return
        <entry name="OEBPS/title.xhtml" type="xml">{$title-xhtml}</entry>
};

(:~
    Helper function, creates the OEBPS/cover.html file.

    @param $volume the volume's ID
    @return the entry for the OEBPS/cover.html file
:)
declare function epub:title-xhtml-body($fileDesc as element()?, $config) {
    <div xmlns="http://www.w3.org/1999/xhtml" id="title">
        { epub:fix-namespaces($pm-config:epub-transform($fileDesc, map { "root": $fileDesc }, $config?odd)) }
    </div>
};

(:~
    Helper function, creates the XHTML files for the body of the EPUB.

    @param $text the tei:text element for the file, which contains the divs to be processed into the EPUB
    @return the serialized XHTML page, wrapped in an entry element
:)
declare function epub:body-xhtml-entries($doc as document-node(), $config) {
    let $div := nav:get-section($config?docConfig, $doc)
    let $entries := epub:body-xhtml($div, $config)
    return
        $entries
};

declare function epub:body-xhtml($node, $config) {
    let $next := nav:get-next($config?docConfig, $node, "div")
    let $content := pages:get-content($config?docConfig, $node)
    let $title := nav:get-section-heading($config?docConfig, $content)/node()
    let $title :=
        if ($title) then
            $pm-config:epub-transform($title, map { "root": $title }, $config?odd)
        else
            "--no title---"
    let $body := $pm-config:epub-transform($content, map { "root": $node }, $config?odd)
    let $body-xhtml:= epub:assemble-xhtml(string-join($title), $config?metadata?language, epub:fix-namespaces($body))
    return (
        <entry name="{concat('OEBPS/', epub:generate-id($node), '.xhtml')}" type="xml">{$body-xhtml}</entry>,
        if ($next) then
            epub:body-xhtml($next, $config)
        else
            ()
    )
};

(:~
    Helper function, creates the CSS entry for the EPUB.

    @param $db-path-to-css the db path to the required static resources (cover.jpg, stylesheet.css)
    @return the CSS entry
:)
declare function epub:stylesheet-entry($css as xs:string) {
    <entry name="OEBPS/stylesheet.css" type="binary">{util:string-to-binary($css)}</entry>
};

declare function epub:nav-entry($config, $text) {
    let $toc :=
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="{$config?metadata?language}"
            xml:lang="{$config?metadata?language}">
            <head>
                <title>Navigation</title>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            </head>
            <body>
                <nav epub:type="toc">
                {
                    epub:toc-nav-div($config, nav:get-section($config?docConfig, $text)/..)
                }
                </nav>
            </body>
        </html>
    return
        <entry name="OEBPS/nav.xhtml" type="xml">{$toc}</entry>
};

declare function epub:toc-nav-div($config, $root as element()) {
    <ol xmlns="http://www.w3.org/1999/xhtml">
    {
        let $divs := nav:get-subsections($config?docConfig, $root)
        for $div in $divs
        let $headings := nav:get-section-heading($config?docConfig, $div)
        let $html :=
            if ($headings) then
                normalize-space(string-join($headings//text()))
            else
                "[no title]"
        let $file := epub:generate-id(nav:get-section-for-node($config?docConfig, $div))
        let $id := if ($div/@xml:id) then $div/@xml:id else epub:generate-id($div)
        return
            <li>
                <a href="{$file}.xhtml#{$id}">{$html}</a>
                { epub:toc-nav-div($config, $div) }
            </li>
    }
    </ol>
};

(:~
    Helper function, creates the OEBPS/toc.ncx file.

    @param $urn the EPUB's urn
    @param $text the tei:text element for the file, which contains the divs to be processed into the EPUB
    @return the NCX element's entry
:)
declare function epub:toc-ncx-entry($config, $text) {
    let $toc-ncx :=
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
            <head>
                <meta name="dtb:uid" content="{$config?metadata?urn}"/>
                <meta name="dtb:depth" content="2"/>
                <meta name="dtb:totalPageCount" content="0"/>
                <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            <docTitle>
                <text>{$config?metadata?title}</text>
            </docTitle>
            <navMap>
                <navPoint id="navpoint-title" playOrder="1">
                    <navLabel>
                        <text>Title</text>
                    </navLabel>
                    <content src="title.xhtml"/>
                </navPoint>
                {
                    counter:create("teipublisher-epub-toc")[2],
                    epub:toc-ncx-div($config, nav:get-section($config?docConfig, $text)/.., 1),
                    counter:destroy("teipublisher-epub-toc")[2]
                }
            </navMap>
        </ncx>
    return
        <entry name="OEBPS/toc.ncx" type="xml">{$toc-ncx}</entry>
};

declare function epub:toc-ncx-div($config, $root as element(), $start as xs:int) {
    let $divs := nav:get-subsections($config?docConfig, $root)
    for $div at $count in $divs
    let $headings := nav:get-section-heading($config?docConfig, $div)
    let $html :=
        if ($headings) then
            normalize-space(string-join($headings//text()))
        else
            "[no title]"
    let $file := epub:generate-id(nav:get-section-for-node($config?docConfig, $div))
    let $id := if ($div/@xml:id) then $div/@xml:id else epub:generate-id($div)
    return
        <navPoint id="navpoint-{$id}" playOrder="{counter:next-value('teipublisher-epub-toc') + $start}" xmlns="http://www.daisy.org/z3986/2005/ncx/">
            <navLabel>
                <text>{$html}</text>
            </navLabel>
            <content src="{$file}.xhtml#{$id}"/>
            { epub:toc-ncx-div($config, $div, $start) }
        </navPoint>
};

(:~
    Helper function, contains the basic XHTML shell used by all XHTML files in the EPUB package.

    @param $title the page's title
    @param $body the body content
    @return the serialized XHTML element
:)
declare function epub:assemble-xhtml($title, $language, $body) {
    let $footnotes := $body//xhtml:aside[@ep:type="footnote"]
    return
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="{$language}">
            <head>
                <title>{$title}</title>
                <link type="text/css" rel="stylesheet" href="stylesheet.css"/>
            </head>
            <body>
                {
                    if ($footnotes) then (
                        epub:strip-footnotes($body),
                        <section epub:type="footnotes">{$footnotes}</section>
                    ) else
                        $body
                }
            </body>
        </html>
};

declare function epub:strip-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case document-node() return
                document {
                    epub:strip-footnotes($node/node())
                }
            case element(xhtml:aside) return
                if ($node[@ep:type="footnote"]) then
                    ()
                else
                    $node
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    epub:strip-footnotes($node/node())
                }
            default return $node
};


declare function epub:fix-namespaces($nodes as item()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element() return
                element { QName("http://www.w3.org/1999/xhtml", local-name($node)) } {
                    $node/@*, for $child in $node/node() return epub:fix-namespaces($child)
                }
            default return
                $node
};

declare function epub:generate-id($node as node()) {
    translate(generate-id($node), ".", "_")
};
