(: 
 : Copyright 2015, Wolfgang Meier
 : 
 : This software is dual-licensed: 
 : 
 : 1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
 : http://creativecommons.org/licenses/by-sa/3.0/ 
 : 
 : 2. http://www.opensource.org/licenses/BSD-2-Clause 
 : 
 : All rights reserved. Redistribution and use in source and binary forms, with or without 
 : modification, are permitted provided that the following conditions are met: 
 : 
 : * Redistributions of source code must retain the above copyright notice, this list of 
 : conditions and the following disclaimer. 
 : * Redistributions in binary form must reproduce the above copyright
 : notice, this list of conditions and the following disclaimer in the documentation
 : and/or other materials provided with the distribution. 
 : 
 : This software is provided by the copyright holders and contributors "as is" and any 
 : express or implied warranties, including, but not limited to, the implied warranties 
 : of merchantability and fitness for a particular purpose are disclaimed. In no event 
 : shall the copyright holder or contributors be liable for any direct, indirect, 
 : incidental, special, exemplary, or consequential damages (including, but not limited to, 
 : procurement of substitute goods or services; loss of use, data, or profits; or business
 : interruption) however caused and on any theory of liability, whether in contract,
 : strict liability, or tort (including negligence or otherwise) arising in any way out
 : of the use of this software, even if advised of the possibility of such damage.
 :)
xquery version "3.1";

(:~
 : Parses an ODD and generates an XQuery transformation module based on
 : the TEI Simple Processing Model.
 : 
 : @author Wolfgang Meier
 :)
module namespace pm="http://www.tei-c.org/tei-simple/xquery/model";

import module namespace xqgen="http://www.tei-c.org/tei-simple/xquery/xqgen" at "xqgen.xql";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $pm:ERR_TOO_MANY_MODELS := xs:QName("pm:too-many-models");
declare variable $pm:MULTIPLE_FUNCTIONS_FOUND := xs:QName("pm:multiple-functions");
declare variable $pm:NOT_FOUND := xs:QName("pm:not-found");

(:~
 : Parse the given ODD and generate an XQuery transformation module.
 : 
 : @param $odd the root node of the ODD document
 : @param $modules an array of maps. Each map defines a module to be used for resolving
 : processing model functions. The first function whose name and parameters match the behaviour
 : will be used.
 : @param output the output method to use ("web" by default) 
 :)
declare function pm:parse($odd as element(), $modules as array(*), $output as xs:string*) as map(*) {
    let $output := if (exists($output)) then $output else "web"
    let $uri := "http://www.tei-c.org/tei-simple/models/" || util:document-name($odd)
    let $root := $odd/ancestor-or-self::tei:TEI
    let $prefixes := in-scope-prefixes($root)[not(. = ("", "xml"))]
    let $namespaces := $prefixes ! namespace-uri-for-prefix(., $root)
    let $moduleDesc := pm:load-modules($modules)
    let $xqueryXML :=
        <xquery>
            <comment type="xqdoc">
                Transformation module generated from TEI ODD extensions for processing models.
                
                ODD: { document-uri(root($odd)) }
            </comment>
            <module prefix="model" uri="{$uri}">
                <default-element-namespace>http://www.tei-c.org/ns/1.0</default-element-namespace>
                <declare-namespace prefix="xhtml" uri="http://www.w3.org/1999/xhtml"/>
                <!-- 
                    Should dynamically generate namespace declarations for all namespaces defined
                    on the root element of the odd. Doesn't work due to merge process though.
                {
                    for-each-pair($prefixes, $namespaces, function($prefix, $ns) {
                        <declare-namespace prefix="{$prefix}" uri="{$ns}"/>
                    })
                } -->
                <import-module prefix="css" uri="http://www.tei-c.org/tei-simple/xquery/css" at="{system:get-module-load-path()}/css.xql"/>
                { pm:import-modules($modules) }
                <comment type="xqdoc">
                    Main entry point for the transformation.
                </comment>
                <function name="model:transform">
                    <param>$options as map(*)</param>
                    <param>$input as node()*</param>
                    <body>
let $config :=
    map:new(($options,
        map {{
            "output": [{ string-join(for $out in $output return '"' || $out || '"', ",")}],
            "odd": "{ document-uri(root($odd)) }",
            "apply": model:apply#2,
            "apply-children": model:apply-children#3
        }}
    ))
    return
        model:apply($config, $input)
                    </body>
                </function>
                <function name="model:apply">
                    <param>$config as map(*)</param>
                    <param>$input as node()*</param>
                    <body>
                        <let var="parameters">
                            <expr>if (exists($config?parameters)) then $config?parameters else map {{}}</expr>
                            <return>
                                <var>input</var>
                                <bang/>
                                <sequence>
                                    <item>
                                        <typeswitch op=".">
                                            {
                                                for $spec in $odd//tei:elementSpec[.//tei:model]
                                                let $case := pm:elementSpec($spec, $moduleDesc, $output)
                                                return
                                                    if (exists($case)) then
                                                        <case test="element({$spec/@ident})">
                                                        {$case}
                                                        </case>
                                                    else
                                                        ()
                                            }
                                            {
                                                if ($output = "web") then
                                                    <case test="element(exist:match)">
                                                        <function-call name="{$modules?1?prefix}:match">
                                                            <param>$config</param>
                                                            <param>.</param>
                                                            <param>.</param>
                                                        </function-call>
                                                    </case>
                                                else
                                                    ()
                                            }
                                            <case test="text() | xs:anyAtomicType">
                                                <function-call name="{$modules?1?prefix}:escapeChars">
                                                    <param>.</param>
                                                </function-call>
                                            </case>
                                            <default>
                                                <function-call name="$config?apply">
                                                    <param>$config</param>
                                                    <param>./node()</param>
                                                </function-call>
                                            </default>
                                        </typeswitch>
                                    </item>
                                </sequence>
                            </return>
                        </let>
                    </body>
                </function>
                <function name="model:apply-children">
                    <param>$config as map(*)</param>
                    <param>$node as element()</param>
                    <param>$content as item()*</param>
                    <body>
$content ! (
    typeswitch(.)
        case element() return
            if (. is $node) then
                $config?apply($config, ./node())
            else
                $config?apply($config, .)
        default return
            {$modules?1?prefix}:escapeChars(.)
)</body>
            </function>
            </module>
        </xquery>
    return
        map {
            "uri": $uri,
            "code": xqgen:generate($xqueryXML, 0)
        }
};

declare function pm:load-modules($modules as array(*)) as array(*) {
    array:for-each($modules, function($module) {
        map:new(($module, map { "description": inspect:inspect-module(xs:anyURI($module?at)) }))
    })
};

declare %private function pm:import-modules($modules as array(*)) {
    array:for-each($modules, function($module) {
        <import-module prefix="{$module?prefix}" uri="{$module?uri}" at="{$module?at}"/>
    })
};

declare %private function pm:elementSpec($spec as element(tei:elementSpec), $modules as array(*), $output as xs:string+) {
    pm:process-models(
        $spec/@ident, 
        $spec/(tei:model[not(@output)]|tei:model[@output = $output]|tei:modelSequence),
        $modules,
        $output
    )
};

declare %private function pm:process-models($ident as xs:string, $models as element()+, $modules as array(*),
    $output as xs:string+) {
    if ($models[@predicate]) then
        fold-right($models[@predicate], (), function($cond, $zero) {
            <if test="{$cond/@predicate}">
                <then>{pm:model-or-sequence($ident, $cond, $modules, $output)}</then>
                {
                    if ($zero) then
                        <else>{$zero}</else>
                    else
                        <else>
                        {
                            if ($models[not(@predicate)]) then
                                if (count($models[not(@predicate)]) > 1 and not($models/parent::tei:modelSequence)) then
                                    error($pm:ERR_TOO_MANY_MODELS, "More than one model without predicate found outside modelSequence")
                                else
                                    pm:model-or-sequence($ident, $models[not(@predicate)], $modules, $output)
                            else
                                <function-call name="$config?apply">
                                    <param>$config</param>
                                    <param>./node()</param>
                                </function-call>
                        }
                        </else>
                }
            </if>
        })
    else if (count($models) > 1 and not($models/parent::tei:modelSequence)) then
        error($pm:ERR_TOO_MANY_MODELS, "More than one model without predicate found outside modelSequence")
    else
        $models ! pm:model-or-sequence($ident, ., $modules, $output)
};

declare %private function pm:model-or-sequence($ident as xs:string, $models as element()+, 
    $modules as array(*), $output as xs:string+) {
    for $model in $models
    return
        typeswitch($model)
            case element(tei:model) return
                pm:model($ident, $model, $modules)
            case element(tei:modelSequence) return
                pm:modelSequence($ident, $model, $modules, $output)
            default return
                ()
};

declare %private function pm:model($ident as xs:string, $model as element(tei:model), $modules as array(*)) {
    let $behaviour := $model/@behaviour
    let $task := normalize-space($model/@behaviour)
    let $params := $model/tei:param
    let $params := if (empty($params[@name="content"])) then ($params, <tei:param name="content">.</tei:param>) else $params
    let $fn := pm:lookup($modules, $task, count($params) + 3)
    return
        if (exists($fn)) then (
            if (count($fn?function) > 1) then
                <comment>More than one function found matching behaviour {$behaviour/string()}</comment>
            else
                (),
            let $signature := $fn?function[1]
            let $classes := pm:get-class($ident, $model)
            return
                try {
                    if ($model/tei:desc) then
                        <comment>{$model/tei:desc}</comment>
                    else
                        (),
                    <function-call name="{$fn?prefix}:{$task}">
                        <param>$config</param>
                        <param>.</param>
                        <param>
                        {
                            if ($model/@useSourceRendition = "true") then
                                <function-call name="css:get-rendition">
                                    <param>.</param>
                                    <param>({string-join(for $class in $classes return '"' || $class || '"', ", ")})</param>
                                </function-call>
                            else 
                                "(" || string-join(for $class in $classes return '"' || $class || '"', ", ") || ")"
                        }
                        </param>
                        {
                            pm:map-parameters($signature, $params)
                        }
                    </function-call>
                } catch pm:not-found {
                    <comment>Failed to map function for behavior {$behaviour/string()}. {$err:description}</comment>,
                    <comment>{serialize($model)}</comment>,
                    "()"
                }
        ) else (
            <comment>No function found for behavior: {$behaviour/string()}</comment>,
            <function-call name="$config?apply">
                <param>$config</param>
                <param>./node()</param>
            </function-call>
        )
};

declare %private function pm:modelSequence($ident as xs:string, $seq as element(tei:modelSequence), 
    $modules as array(*), $output as xs:string+) {
    <sequence>
    {
        for $model in $seq/*[not(@output)] | $seq/*[@output = $output][1]
        return
            <item>
            {
                if ($model/@predicate) then
                    <if test="{$model/@predicate}">
                        <then>{pm:model-or-sequence($ident, $model, $modules, $output)}</then>
                        <else>()</else>
                    </if>
                else
                    pm:model-or-sequence($ident, $model, $modules, $output)
            }
            </item>
    }
    </sequence>
};

declare %private function pm:get-class($ident as xs:string, $model as element(tei:model)) as xs:string+ {
    let $count := count($model/../tei:model)
    let $genClass := $ident || (if ($count > 1) then count($model/preceding-sibling::tei:model) + 1 else ())
    return
        if ($model/@cssClass) then
            ($genClass, $model/@cssClass/string())
        else
            $genClass
};

declare %private function pm:lookup($modules as array(*), $task as xs:string, $arity as xs:int) as map(*)? {
    if (array:size($modules) > 0) then
        let $module := $modules?(array:size($modules))
        let $moduleDesc := $module?description
        let $fn := $moduleDesc/function[@name = $moduleDesc/@prefix || ":" || $task]
        return
            if (exists($fn)) then
                map { "function": $fn, "prefix": $module?prefix }
            else
                pm:lookup(array:subarray($modules, 1, array:size($modules) - 1), $task, $arity)
    else
        ()
};

declare function pm:map-parameters($signature as element(function), $params as element(tei:param)+) {
    for $arg in subsequence($signature/argument, 4)
    let $mapped := $params[@name = $arg/@var]
    return
        if ($mapped) then
            <param>{if ($mapped != "") then $mapped/string() else "()"}</param>
        else if ($arg/@cardinality = ("zero or one", "zero or more")) then
            <param>()</param>
        else
            error($pm:NOT_FOUND, "No matching parameter found for argument " || $arg/@var)
};