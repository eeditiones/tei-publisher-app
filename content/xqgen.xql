xquery version "3.1";

(:~
 : Utility functions for generating XQuery code out of a simple XML descriptor.
 : 
 : @author Wolfgang Meier
 :)
module namespace xqgen="http://www.tei-c.org/tei-simple/xquery/xqgen";

declare variable $xqgen:LF := "&#10;";
declare variable $xqgen:LFF := "&#10;&#10;";

declare variable $xqgen:SPACES := "                                                                                                      ";

declare function xqgen:generate($nodes as node()*, $indent as xs:int) {
    string-join(
        for $node in $nodes
        return
            typeswitch ($node)
                case element(xquery) return
                    xqgen:generate($node/*, $indent)
                case element(module) return
                    'xquery version "3.0";' || $xqgen:LFF ||
                    'module namespace ' || $node/@prefix || '="' || $node/@uri || '";' || $xqgen:LFF ||
                    xqgen:generate($node/*, $indent)
                case element(default-element-namespace) return
                    'declare default element namespace "' || $node/string() || '";' || $xqgen:LFF
                case element(import-module) return
                    string-join((
                        'import module namespace ' || $node/@prefix || '="' || $node/@uri || '"' ||
                        (if ($node/@at) then ' at "' || $node/@at || '"' else ()),
                        ';' || $xqgen:LFF
                    ))
                case element(function) return
                    'declare function ' || $node/@name || '(' ||
                    string-join(
                        for $param in $node/param
                        return
                            $param/string(),
                        ", "
                    ) ||
                    ') {' || $xqgen:LF || xqgen:indent($indent + 1) ||
                    xqgen:generate($node/body/node(), $indent + 1) || $xqgen:LF ||
                    xqgen:indent($indent) || '};' || $xqgen:LFF
                case element(typeswitch) return
                    xqgen:indent($indent) ||
                    'typeswitch(' || $node/@op || ')' || $xqgen:LF ||
                    xqgen:generate($node/case, $indent + 1) ||
                    xqgen:generate($node/default, $indent + 1)
                case element(case) return
                    xqgen:indent($indent) ||
                    'case ' || $node/@test || ' return' || $xqgen:LF ||
                    xqgen:generate($node/node(), $indent + 1) || $xqgen:LF
                case element(default) return
                    xqgen:indent($indent) ||
                    'default return ' || $xqgen:LF || xqgen:generate($node/node(), $indent + 1) || $xqgen:LF
                case element(function-call) return
                    xqgen:indent($indent) ||
                    $node/@name || "(" ||
                    string-join(for $param in $node/param return xqgen:generate($param/node(), 0), ", ") ||
                    ")"
                case element(comment) return
                    switch ($node/@type)
                        case "xqdoc" return
                            xqgen:indent($indent) ||
                            "(:~" || $xqgen:LF ||
                            replace($node/string(), "\s*\n\s*", $xqgen:LF || xqgen:indent($indent + 1)) || 
                            $xqgen:LF || " :)" || $xqgen:LF
                        default return
                            xqgen:indent($indent) ||
                            "(: " || normalize-space($node/node()) || " :)" || $xqgen:LF
                case element(if) return
                    xqgen:indent($indent) ||
                    "if (" || $node/@test || ") then" || $xqgen:LF ||
                    xqgen:generate($node/*, $indent)
                case element(then) return
                    xqgen:generate($node/node(), $indent + 1) || $xqgen:LF
                case element(else) return
                    xqgen:indent($indent) ||
                    "else" || $xqgen:LF ||
                    xqgen:generate($node/node(), $indent + 1)
                case element(var) return
                    "$" || $node/string()
                case element(bang) return
                    " ! "
                case element(sequence) return
                    xqgen:indent($indent) || "(" || $xqgen:LF ||
                    string-join(for $item in $node/item return xqgen:generate($item/node(), $indent + 1), "," || $xqgen:LF) ||
                    $xqgen:LF ||
                    xqgen:indent($indent) || ")" || $xqgen:LF
                case text() return
                    xqgen:indent($node, $indent)
                default return
                    ()
    )
};

declare %private function xqgen:indent($amount as xs:int) {
    substring($xqgen:SPACES, 1, $amount * 4)
};

declare %private function xqgen:indent($str as xs:string, $amount as xs:int) {
    xqgen:indent($amount) ||
    replace($str, "\n", $xqgen:LF || xqgen:indent($amount))
};