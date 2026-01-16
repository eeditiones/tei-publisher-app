xquery version "3.1";

module namespace landing="http://teipublisher.com/ns/templates/landing-page";

import module namespace page="http://teipublisher.com/ns/templates/page" at "page.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function landing:section($context as map(*), $name as xs:string, $root as node(), $odd as xs:string?) {
    let $lang := page:parameter($context, 'lang')
    let $nodes := head(($root//tei:div[@type=$name][@xml:lang=$lang], $root//tei:div[@type=$name], $root/id($name)))
    let $odd := head(($odd, $context?defaults?odd, 'landing.odd'))
    return
        page:transform($nodes, map { "browse-url": $context?defaults?browse }, $odd)
};

declare function landing:lang($context as map(*), $name as xs:string, $root as node(), $odd as xs:string?) {
    let $lang := page:parameter($context, 'lang')
   
    return
        $lang
};