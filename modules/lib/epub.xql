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
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

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
    let $config := map:merge(($config, map { "docConfig": tpu:parse-pi(root($doc), "div") }))
    let $xhtml := epub:body-xhtml-entries(root($doc), $config)
    let $entries :=
        (
            epub:mimetype-entry(),
            epub:container-entry(),
            epub:content-opf-entry($config, $doc, $xhtml),
            epub:title-xhtml-entry($config?metadata?language, $doc, $config),
            epub:table-of-contents-xhtml-entry($config, $doc, false()),
            epub:images-entry($doc, $xhtml),
            epub:stylesheet-entry($css),
            epub:toc-ncx-entry($config, $doc),
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
        let $id := replace($entry/@name, '^OEBPS/(.*)\.html$', '$1')
        return
            <item xmlns="http://www.idpf.org/2007/opf"
                id="{$id}" href="{$id}.html" media-type="application/xhtml+xml"/>
    let $refs :=
        for $entry in $xhtml
        let $id := replace($entry/@name, '^OEBPS/(.*)\.html$', '$1')
        return
            <itemref xmlns="http://www.idpf.org/2007/opf" idref="{$id}"/>
    let $content-opf :=
        <package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0" unique-identifier="bookid">
            <metadata>
                <dc:title>{$config?metadata?title}</dc:title>
                <dc:creator>{$config?metadata?creator}</dc:creator>
                <dc:identifier id="bookid">{$config?metadata?urn}</dc:identifier>
                <dc:language>{$config?metadata?language}</dc:language>
            </metadata>
            <manifest>
                <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
                <item id="title" href="title.html" media-type="application/xhtml+xml"/>
                <item id="table-of-contents" href="table-of-contents.html" media-type="application/xhtml+xml"/>
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
                <itemref idref="table-of-contents"/>
                {
                    $refs
                }
            </spine>
            <guide>
                <reference href="table-of-contents.html" type="toc" title="Table of Contents"/>
                {
                (: first text div :)
                let $doc := root($text)
                let $first-text-div := nav:get-section($config?docConfig, $doc)
                let $id := epub:generate-id($first-text-div)
                let $title := $first-text-div/tei:head
                return
                    <reference href="{$id}.html" type="text" title="{$title}"/>
                }
                {
                (: index div :)
                if ($text/id('index')) then
                    <reference href="index.html" type="index" title="Index"/>
                else
                    ()
                }
            </guide>
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
        <entry name="OEBPS/title.html" type="xml">{$title-xhtml}</entry>
};

(:~
    Helper function, creates the OEBPS/cover.html file.

    @param $volume the volume's ID
    @return the entry for the OEBPS/cover.html file
:)
declare function epub:title-xhtml-body($fileDesc as element()?, $config) {
    <div xmlns="http://www.w3.org/1999/xhtml" id="title">
        { $pm-config:epub-transform($fileDesc, map { "root": $fileDesc }, $config?odd) }
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
        ($entries, epub:endnotes-xhtml-entry($config?metadata?language, $entries))
};

declare function epub:body-xhtml($node, $config) {
    let $next := $config:next-page($config?docConfig, $node, "div")
    let $content := pages:get-content($config?docConfig, $node)
    let $title := nav:get-section-heading($config?docConfig, $content)
    let $body := $pm-config:epub-transform($content, map { "root": $node }, $config?odd)
    let $body-xhtml:= epub:assemble-xhtml($title, $config?metadata?language, epub:fix-namespaces($body))
    return (
        <entry name="{concat('OEBPS/', epub:generate-id($node), '.html')}" type="xml">{$body-xhtml}</entry>,
        if ($next) then
            epub:body-xhtml($next, $config)
        else
            ()
    )
};

declare function epub:endnotes-xhtml-entry($language, $entries as element()*) {
    <entry name="OEBPS/endnotes.html" type="xml">
    {
        epub:assemble-xhtml("Notes", $language, epub:fix-namespaces(
            <div xmlns="http://www.w3.org/1999/xhtml">
                <h1>Notes</h1>
                <table class="endnotes">
                {
                    for $entry in $entries
                    for $note in $entry//*[@class = "endnote"]
                    return
                        <tr>
                            <td id="{$note/@id}" class="note-number">{$note/preceding-sibling::*[1]/text()}</td>
                            <td>
                                {$note/node(), " "}
                                <a href="{substring-after($entry/@name, 'OEBPS/')}#A{$note/@id}">Return</a>
                            </td>
                        </tr>
                }
                </table>
            </div>
        ))
    }
    </entry>
};

(:~
    Helper function, creates the CSS entry for the EPUB.

    @param $db-path-to-css the db path to the required static resources (cover.jpg, stylesheet.css)
    @return the CSS entry
:)
declare function epub:stylesheet-entry($css as xs:string) {
    <entry name="OEBPS/stylesheet.css" type="binary">{util:string-to-binary($css)}</entry>
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
                    <content src="title.html"/>
                </navPoint>
                <navPoint id="navpoint-table-of-contents" playOrder="2">
                    <navLabel>
                        <text>Table of Contents</text>
                    </navLabel>
                    <content src="table-of-contents.html"/>
                </navPoint>
                {
                    for $text in $text//tei:text/*
                    return
                        epub:toc-ncx-div($config, $text, 2)
                }
            </navMap>
        </ncx>
    return
        <entry name="OEBPS/toc.ncx" type="xml">{$toc-ncx}</entry>
};

declare function epub:toc-ncx-div($config, $root as element(), $start as xs:int) {
    for $div in $root/tei:div
    let $id := if ($div/@xml:id) then $div/@xml:id else epub:generate-id($div)
    let $file := epub:generate-id($div/ancestor-or-self::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1])
    let $index := count($div/preceding::tei:div[ancestor::tei:body]) + count($div/ancestor::tei:div) + 1
    let $text :=
        if ($div/tei:head) then
            $pm-config:epub-transform($div/tei:head[1], map { "header": "short", "root": $div }, $config?odd)//text()
        else
            "[no title]"
    return
        <navPoint id="navpoint-{$id}" playOrder="{$start + $index}" xmlns="http://www.daisy.org/z3986/2005/ncx/">
            <navLabel>
                <text>{$text}</text>
            </navLabel>
            <content src="{$file}.html#{$id}"/>
            { epub:toc-ncx-div($config, $div, $start)}
        </navPoint>
};

(:~
    Helper function, creates the OEBPS/table-of-contents.html file.

    @param $title the page's title
    @param $text the tei:text element for the file, which contains the divs to be processed into the EPUB
    @return the entry for the OEBPS/table-of-contents.html file
:)
declare function epub:table-of-contents-xhtml-entry($config, $doc, $suppress-documents) {
    let $body :=
        <div xmlns="http://www.w3.org/1999/xhtml" id="table-of-contents">
            <h2>Contents</h2>
            <ul>{
                for $div in $doc//tei:body/tei:div
                let $text :=
                    if ($div/tei:head) then
                        $pm-config:epub-transform($div/tei:head[1], map { "header": "short", "root": $div }, $config?odd)//text()
                    else
                        "[no title]"
                let $id := if ($div/@xml:id) then $div/@xml:id else epub:generate-id($div)
                return
                    <li>
                        <a href="{epub:generate-id($div)}.html#{$id}">
                        { 
                            $text
                        }
                        </a>
                    </li>
            }</ul>
        </div>
    let $table-of-contents-xhtml := epub:assemble-xhtml($config?metadata?title, $config?metadata?language, $body)
    return
        <entry name="OEBPS/table-of-contents.html" type="xml">{$table-of-contents-xhtml}</entry>
};

(:~
    Helper function, contains the basic XHTML shell used by all XHTML files in the EPUB package.

    @param $title the page's title
    @param $body the body content
    @return the serialized XHTML element
:)
declare function epub:assemble-xhtml($title, $language, $body) {
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{$language}">
        <head>
            <title>{$title}</title>
            <link type="text/css" rel="stylesheet" href="stylesheet.css"/>
        </head>
        <body>
            {$body}
        </body>
    </html>
};

declare function epub:fix-namespaces($nodes as node()*) {
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
