xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:index() {
    for $doc in collection($config:data-root)/tei:TEI
    let $titleStmt := (
        $doc//tei:sourceDesc/tei:biblFull/tei:titleStmt,
        $doc//tei:fileDesc/tei:titleStmt
    )
    let $index :=
        <doc>
            {
                for $title in $titleStmt/tei:title
                return
                    <field name="title" store="yes">{string-join($title/text(), " ")}</field>
            }
            {
                for $author in $titleStmt/tei:author
                let $normalized := replace($author/text(), "^([^,]*,[^,]*),?.*$", "$1")
                return
                    <field name="author" store="yes">{$normalized}</field>
            }
            <field name="year" store="yes">{$doc/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:date/text()}</field>
            <field name="file" store="yes">{substring-before(util:document-name($doc), ".xml")}</field>
        </doc>
    return
        ft:index(document-uri(root($doc)), $index)
};

declare function local:clear() {
    for $doc in collection($config:data-root)/tei:TEI
    return
        ft:remove-index(document-uri(root($doc)))
};

local:clear(),
local:index(),
<p>Document metadata index updated successfully!</p>