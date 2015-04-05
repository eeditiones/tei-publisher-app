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

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Parse the given ODD and generate an XQuery transformation module.
 : 
 : @param $odd the root node of the ODD document
 : @param $modules an array of maps. Each map defines a module to be used for resolving
 : processing model functions. The first function whose name and parameters match the behaviour
 : will be used.
 : @param output the output method to use ("web" by default) 
 :)
declare function pm:parse($odd as element(), $modules as array(*), $output as xs:string?) as map(*) {
    let $output := if ($output) then $output else "web"
    let $uri := "http://www.tei-c.org/tei-simple/models/" || util:document-name($odd)
    let $xqueryXML :=
        <xquery>
            <comment type="xqdoc">
                Transformation module generated from TEI ODD extensions for processing models.
                
                ODD: { document-uri(root($odd)) }
            </comment>
            <module prefix="model" uri="{$uri}">
                <default-element-namespace>http://www.tei-c.org/ns/1.0</default-element-namespace>
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
            "output": "{ $output }",
            "odd": "{ document-uri(root($odd)) }",
            "apply": model:apply#2
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
                        <var>input</var>
                        <bang/>
                        <sequence>
                            <item>
                                <typeswitch op=".">
                                    {
                                        for $spec in $odd//tei:elementSpec[.//tei:model]
                                        let $case := pm:elementSpec($spec, $modules, $output)
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
                    </body>
                </function>
            </module>
        </xquery>
    return
        map {
            "uri": $uri,
            "code": xqgen:generate($xqueryXML, 0)
        }
};

declare %private function pm:import-modules($modules as array(*)) {
    array:for-each($modules, function($module) {
        util:import-module($module?uri, $module?prefix, $module?at),
        <import-module prefix="{$module?prefix}" uri="{$module?uri}" at="{$module?at}"/>
    })
};

declare %private function pm:elementSpec($spec as element(tei:elementSpec), $modules as array(*), $output as xs:string) {
    pm:process-models(
        $spec/@ident, 
        $spec/(tei:model[not(@output)]|tei:model[@output = $output]|tei:modelSequence),
        $modules,
        $output
    )
};

declare %private function pm:process-models($ident as xs:string, $models as element()+, $modules as array(*),
    $output as xs:string) {
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
    else
        $models ! pm:model-or-sequence($ident, ., $modules, $output)
};

declare %private function pm:model-or-sequence($ident as xs:string, $models as element()+, 
    $modules as array(*), $output as xs:string) {
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
    let $task := substring-before(normalize-space($model/@behaviour),'(')
    let $argStr := replace(normalize-space($behaviour),'[^\(]*\((.*)\)$','$1')
    let $args := analyze-string($argStr, "('.*?'|&quot;.*?&quot;|[^\(]+?|\(.*?\))(?:\s*,\s*|$)")//fn:group/string()
    let $params := if (count($args) = 0) then "." else $args
    
    let $fn := pm:lookup($modules, $task, count($params) + 3)
    return
        if (exists($fn)) then
            let $count := count($model/../tei:model)
            let $class := $ident || (if ($count > 1) then count($model/preceding-sibling::tei:model) + 1 else ())
            return (
                if ($model/tei:desc) then
                    <comment>{$model/tei:desc}</comment>
                else
                    (),
                <function-call name="{$modules?1?prefix}:{$task}">
                    <param>$config</param>
                    <param>.</param>
                    <param>
                    {
                        if ($model/@useSourceRendition = "true") then
                            <function-call name="{$modules?1?prefix}:get-rendition">
                                <param>.</param>
                                <param>{'"' || $class || '"'}</param>
                            </function-call>
                        else 
                            '"' || $class || '"'
                    }
                    </param>
                    {
                        $params ! <param>{.}</param>
                    }
                </function-call>
        ) else (
            <comment>No function found for behavior: {$behaviour/string()}</comment>,
            <function-call name="$config?apply">
                <param>$config</param>
                <param>./node()</param>
            </function-call>
        )
};

declare %private function pm:modelSequence($ident as xs:string, $seq as element(tei:modelSequence), 
    $modules as array(*), $output as xs:string) {
    <sequence>
    {
        for $model in $seq/*[not(@output)] | $seq/*[@output = $output]
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

declare %private function pm:lookup($modules as array(*), $task as xs:string, $arity as xs:int) {
    if (array:size($modules) > 0) then
        let $module := array:head($modules)
        let $fn := function-lookup(QName($module?uri, $task), $arity)
        return
            if (exists($fn)) then
                $fn
            else
                pm:lookup(array:tail($modules), $task, $arity)
    else
        ()
};