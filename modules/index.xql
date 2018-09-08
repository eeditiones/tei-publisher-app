xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:index() {
    for $root in $config:data-root
    for $doc in collection($root)/*
    let $index := nav:index(map { "type": nav:document-type($doc) }, $doc)
    return
        if ($index) then
            ft:index(document-uri(root($doc)), $index)
        else
            ()
};

declare function local:clear() {
    for $root in $config:data-root
    for $doc in collection($root)/tei:TEI
    return
        ft:remove-index(document-uri(root($doc)))
};

local:clear(),
local:index(),
<p>Document metadata index updated successfully!</p>
