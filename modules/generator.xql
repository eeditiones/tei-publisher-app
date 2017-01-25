(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

import module namespace tmpl="http://exist-db.org/xquery/template" at "tmpl.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace deploy="http://www.tei-c.org/tei-simple/generator";
declare namespace git="http://exist-db.org/eXide/git";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/javascript";

declare variable $deploy:app-root := request:get-attribute("app-root");

declare variable $deploy:ANT_FILE :=
    <project default="xar" name="$$app$$">
        <xmlproperty file="expath-pkg.xml"/>
        <property name="project.version" value="${{package(version)}}"/>
        <property name="project.app" value="$$app$$"/>
        <property name="build.dir" value="build"/>
        <target name="xar">
            <mkdir dir="${{build.dir}}"/>
            <zip basedir="." destfile="${{build.dir}}/${{project.app}}-${{project.version}}.xar"
                excludes="${{build.dir}}/*"/>
        </target>
    </project>;

declare function deploy:xconf($collection as xs:string, $odd as xs:string, $userData as xs:string*, $permissions as xs:string?) {
    let $mainIndex := request:get-parameter("index", "tei:div")
    let $xconf :=
        <collection xmlns="http://exist-db.org/collection-config/1.0">
            <index xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                <fulltext default="none" attributes="false"/>
                <lucene>
                    <text qname="{$mainIndex}"/>
                    <text qname="tei:head"/>
                    <text match="//tei:sourceDesc/tei:biblFull/tei:titleStmt/tei:title"/>
                    <text match="//tei:fileDesc/tei:titleStmt/tei:title"/>
                </lucene>
            </index>
            <!--triggers>
                <trigger event="update" class="org.exist.collections.triggers.XQueryTrigger">
                    <parameter name="url" value="xmldb:exist://{$collection}/modules/on-odd-changed.xql"/>
                    <parameter name="odd" value="{$odd}"/>
                    <parameter name="collection" value="{$collection}"/>
                </trigger>
            </triggers-->
        </collection>
    return (
        xmldb:store($collection, "collection.xconf", $xconf),
        deploy:mkcol("/db/system/config" || $collection, $userData, $permissions),
        xmldb:store("/db/system/config" || $collection, "collection.xconf", $xconf)
    )
};

declare function deploy:init-simple($collection as xs:string?, $userData as xs:string*, $permissions as xs:string?) {
    let $target := $collection || "/resources/odd"
    let $odd := request:get-parameter("odd", "teipublisher.odd")
    let $oddName := replace($odd, "^([^/\.]+)\.?.*$", "$1")
    let $mkcol := deploy:mkcol($target, $userData, $permissions)
    return (
        deploy:xconf($collection, $odd, $userData, $permissions),
        for $file in ("tei_simplePrint.odd", "teipublisher.odd", $odd)
        let $source := doc($config:odd-root || "/" || $file)
        return (
            xmldb:store($target, $file, $source, "application/xml"),
            if (exists($userData)) then
                let $stored := xs:anyURI($target || "/" || $file)
                return (
                    sm:chmod($stored, $permissions),
                    sm:chown($stored, $userData[1]),
                    sm:chgrp($stored, $userData[2])
                )
            else
                ()
        ),
        deploy:create-configuration($target),
        deploy:mkcol($collection || "/data", $userData, $permissions),
        deploy:mkcol($collection || "/transform", $userData, $permissions),
        xmldb:copy($config:output-root, $collection || "/transform", "teipublisher.fo.css"),
        xmldb:copy($config:output-root, $collection || "/transform", "teipublisher-print.css"),
        if (util:binary-doc-available($config:output-root || "/" || $oddName || "-print.css")) then
            xmldb:copy($config:output-root, $collection || "/transform", $oddName || "-print.css")
        else
            (),
        if (util:binary-doc-available($config:output-root || "/" || $oddName || ".fo.css")) then
            xmldb:copy($config:output-root, $collection || "/transform", $oddName || ".fo.css")
        else
            (),
        for $file in ("master.fo.xml", "page-sequence.fo.xml")
        let $template := repo:get-resource("http://existsolutions.com/apps/tei-publisher-lib", "content/" || $file)
        return
            xmldb:store($config:output-root, $file, $template, "text/xml"),
        deploy:chmod-scripts($collection)
    )
};

declare function deploy:create-configuration($target as xs:string) {
    xmldb:store($target, "configuration.xml",
        document {
            <!--
                Defines extension modules to be loaded for a given output mode, optionally limited to a
                specific odd file. Order is important: the first module function matching a given behaviour
                will be used.

                Every output element may list an arbitrary number of modules, though they should differ by
                uri and prefix.

                "mode" is the mode identification string passed to pmu:process.
                The "odd" is defined by its name, without the .odd suffix.
            -->,
            <modules>
                <output mode="latex">
                    <property name="class">"article"</property>
                    <property name="section-numbers">false()</property>
                    <property name="font-size">"12pt"</property>
                </output>
                <!-- Add custom module -->
                <!--
                <output mode="web" odd="teisimple">
                    <module uri="http://my.com" prefix="ext-html" at="xmldb:exist:///db/apps/my-app/modules/ext-html.xql"/>
                </output>
                -->
            </modules>
        }
    )
};


declare function deploy:chmod-scripts($target as xs:string) {
    sm:chmod(xs:anyURI($target || "/modules/view.xql"), "rwsr-xr-x"),
    sm:chmod(xs:anyURI($target || "/modules/lib/ajax.xql"), "rwsr-xr-x"),
    sm:chmod(xs:anyURI($target || "/modules/lib/regenerate.xql"), "rwsr-xr-x")
};

declare function deploy:store-expath($collection as xs:string?, $userData as xs:string*, $permissions as xs:string?) {
    let $descriptor :=
        <package xmlns="http://expath.org/ns/pkg"
            name="{request:get-parameter('uri', ())}" abbrev="{request:get-parameter('abbrev', ())}"
            version="{request:get-parameter('version', '0.1')}" spec="1.0">
            <title>{request:get-parameter("title", ())}</title>
            <dependency package="http://exist-db.org/apps/shared"/>
            <dependency package="http://existsolutions.com/apps/tei-publisher-lib"/>
        </package>
    return (
        xmldb:store($collection, "expath-pkg.xml", $descriptor, "text/xml"),
        let $targetPath := xs:anyURI($collection || "/expath-pkg.xml")
        return (
            sm:chmod($targetPath, $permissions),
            sm:chown($targetPath, $userData[1]),
            sm:chgrp($targetPath, $userData[2])
        )
    )
};

declare function deploy:repo-descriptor($target as xs:string) {
    <meta xmlns="http://exist-db.org/xquery/repo">
        <description>
        {
            let $desc := request:get-parameter("description", ())
            return
                if ($desc) then $desc else request:get-parameter("title", ())
        }
        </description>
        {
            for $author in request:get-parameter("author", ())
            return
                <author>{$author}</author>
        }
        <website>{request:get-parameter("website", ())}</website>
        <status>{request:get-parameter("status", ())}</status>
        <license>GNU-LGPL</license>
        <copyright>true</copyright>
        <type>{request:get-parameter("type", "application")}</type>
        <target>{$target}</target>
        <prepare>pre-install.xql</prepare>
        <finish>post-install.xql</finish>
        {
            let $owner := request:get-parameter("owner", ())
            return
                if ($owner and $owner != "") then
                    let $group := request:get-parameter("group", "tei")
                    return
                        <permissions user="{$owner}"
                            password="{request:get-parameter('password', ())}"
                            group="{$group}"
                            mode="rw-rw-r--"/>
                else
                    ()
        }
    </meta>
};

declare function deploy:store-repo($descriptor as element(), $collection as xs:string?, $userData as xs:string*, $permissions as xs:string?) {
    (
        xmldb:store($collection, "repo.xml", $descriptor, "text/xml"),
        let $targetPath := xs:anyURI($collection || "/repo.xml")
        return (
            sm:chmod($targetPath, $permissions),
            sm:chown($targetPath, $userData[1]),
            sm:chgrp($targetPath, $userData[2])
        )
    )
};

declare function deploy:mkcol-recursive($collection, $components, $userData as xs:string*, $permissions as xs:string?) {
    if (exists($components)) then
        let $permissions :=
            if ($permissions) then
                deploy:set-execute-bit($permissions)
            else
                "rwxr-x---"
        let $newColl := xs:anyURI(concat($collection, "/", $components[1]))
        return (
            xmldb:create-collection($collection, $components[1]),
            if (exists($userData)) then (
                sm:chmod($newColl, $permissions),
                sm:chown($newColl, $userData[1]),
                sm:chgrp($newColl, $userData[2])
            ) else
                (),
            deploy:mkcol-recursive($newColl, subsequence($components, 2), $userData, $permissions)
        )
    else
        ()
};

declare function deploy:mkcol($path, $userData as xs:string*, $permissions as xs:string?) {
    let $path := if (starts-with($path, "/db/")) then substring-after($path, "/db/") else $path
    return
        deploy:mkcol-recursive("/db", tokenize($path, "/"), $userData, $permissions)
};

declare function deploy:create-collection($collection as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $target := collection($collection)
    return
        if ($target) then
            $target
        else
            deploy:mkcol($collection, $userData, $permissions)
};

declare function deploy:check-group($group as xs:string) {
    if (xmldb:group-exists($group)) then
        ()
    else
        sm:create-group($group)
};

declare function deploy:check-user($repoConf as element()) as xs:string+ {
    let $perms := $repoConf/repo:permissions
    let $user := if ($perms/@user) then $perms/@user/string() else xmldb:get-current-user()
    let $group := if ($perms/@group) then $perms/@group/string() else xmldb:get-user-groups($user)[1]
    let $create :=
        if (xmldb:exists-user($user)) then
            if (index-of(xmldb:get-user-groups($user), $group)) then
                ()
            else (
                deploy:check-group($group),
                xmldb:add-user-to-group($user, $group)
            )
        else (
            deploy:check-group($group),
            xmldb:create-user($user, $perms/@password, $group, ())
        )
    return
        ($user, $group)
};

declare function deploy:target-permissions($repoConf as element()) as xs:string {
    let $permissions := $repoConf/repo:permissions/@mode/string()
    return
        if ($permissions) then
            if ($permissions castable as xs:int) then
                xmldb:permissions-to-string(util:base-to-integer(xs:int($permissions), 8))
            else
                $permissions
        else
            "rw-rw-r--"
};

declare function deploy:set-execute-bit($permissions as xs:string) {
    replace($permissions, "(..).(..).(..).", "$1x$2x$3x")
};

declare function deploy:copy-templates($target as xs:string, $source as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $null := deploy:mkcol($target, $userData, $permissions)
    return
    if (exists(collection($source))) then (
        for $resource in xmldb:get-child-resources($source)
        let $targetPath := xs:anyURI(concat($target, "/", $resource))
        return (
            xmldb:copy($source, $target, $resource),
            let $mime := xmldb:get-mime-type($targetPath)
            let $perms :=
                if ($mime eq "application/xquery") then
                    deploy:set-execute-bit($permissions)
                else $permissions
            return (
                sm:chmod($targetPath, $perms),
                sm:chown($targetPath, $userData[1]),
                sm:chgrp($targetPath, $userData[2])
            )
        ),
        for $childColl in xmldb:get-child-collections($source)
        return
            deploy:copy-templates(concat($target, "/", $childColl), concat($source, "/", $childColl), $userData, $permissions)
    ) else
        ()
};

declare function deploy:store-templates-from-db($target as xs:string, $base as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $template := request:get-parameter("template", "basic")
    let $templateColl := concat($base, "/templates/", $template)
    return
        deploy:copy-templates($target, $templateColl, $userData, $permissions)
};

declare function deploy:chmod($collection as xs:string, $userData as xs:string+, $permissions as xs:string) {
    (
        let $collURI := xs:anyURI($collection)
        return (
            sm:chmod($collURI, $permissions),
            sm:chown($collURI, $userData[1]),
            sm:chgrp($collURI, $userData[2])
        ),
        for $resource in xmldb:get-child-resources($collection)
        let $path := concat($collection, "/", $resource)
        let $targetPath := xs:anyURI($path)
        let $mime := xmldb:get-mime-type($path)
        let $perms :=
            if ($mime eq "application/xquery") then
                deploy:set-execute-bit($permissions)
            else
                $permissions
        return (
            sm:chmod($targetPath, $permissions),
            sm:chown($targetPath, $userData[1]),
            sm:chgrp($targetPath, $userData[2])
        ),
        for $child in xmldb:get-child-collections($collection)
        return
            deploy:chmod(concat($collection, "/", $child), $userData, $permissions)
    )
};

declare function deploy:store-ant($target as xs:string, $permissions as xs:string) {
    let $abbrev := request:get-parameter("abbrev", "")
    let $parameters :=
        <parameters>
            <param name="app" value="{$abbrev}"/>
        </parameters>
    let $antXML := tmpl:expand-template($deploy:ANT_FILE, $parameters)
    return
        xmldb:store($target, "build.xml", $antXML)
};

declare function deploy:expand($collection as xs:string, $resource as xs:string, $parameters as element(parameters)) {
    if (util:binary-doc-available($collection || "/" || $resource)) then
        let $code :=
            let $doc := util:binary-doc($collection || "/" || $resource)
            return
                util:binary-to-string($doc)
        let $expanded := tmpl:parse($code, $parameters)
        return
            xmldb:store($collection, $resource, $expanded)
    else
        ()
};

declare function deploy:expand-xql($target as xs:string) {
    let $name := request:get-parameter("uri", ())
    let $odd := request:get-parameter("odd", "teipublisher.odd")
    let $defaultView := request:get-parameter("default-view", "div")
    let $data-param := request:get-parameter("data-collection", ())
    let $mainIndex := request:get-parameter("index", "tei:div")
    let $data-param :=
        if (ends-with($data-param, "/")) then $data-param else $data-param || "/"
    let $data-root :=
        if ($data-param eq "/") then
            '$config:app-root || "/data"'
        else
            '"' || $data-param || '"'
    let $parameters :=
        <parameters>
            <param name="templates" value=""/>
            <param name="namespace" value="{$name}/templates"/>
            <param name="config-namespace" value="{$name}/config"/>
            <param name="pages-namespace" value="{$name}/pages"/>
            <param name="default-view" value="{$defaultView}"/>
            <param name="config-data" value="{$data-root}"/>
            <param name="config-odd" value="{$odd}"/>
            <param name="config-odd-name" value="{substring-before($odd, '.odd')}"/>
            <param name="default-search" value="{$mainIndex}"/>
        </parameters>
    for $module in ("config.xqm", "pm-config.xql")
    return
        deploy:expand($target || "/modules", $module, $parameters)
};

declare function deploy:store-templates-from-fs($target as xs:string, $base as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $pathSep := util:system-property("file.separator")
    let $template := request:get-parameter("template", "basic")
    let $templatesDir := concat($base, $pathSep, "templates", $pathSep, $template)
    return (
        xmldb:store-files-from-pattern($target, $templatesDir, "**/*", (), true(), "**/.svn/**"),
        deploy:chmod($target, $userData, $permissions)
    )
};

declare function deploy:store-templates($target as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $base := substring-before(system:get-module-load-path(), "/modules")
    return (
        if (starts-with($base, "xmldb:exist://")) then
            deploy:store-templates-from-db($target, $base, $userData, $permissions)
        else
            deploy:store-templates-from-fs($target, $base, $userData, $permissions)
    )
};

declare function deploy:store-libs($target as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $path := system:get-module-load-path()
    for $lib in ("autocomplete.xql", "index.xql", "view.xql", "navigation.xql")
    return (
        xmldb:copy($path, $target || "/modules", $lib),
        deploy:chmod($target || "/modules", $userData, $permissions)
    ),
    let $target := $target || "/modules/lib"
    let $source := system:get-module-load-path() || "/lib"
    return
        deploy:copy-templates($target, $source, $userData, $permissions)
};

declare function deploy:store($collection as xs:string?, $target as xs:string, $expathConf as element()?) {
    let $collection :=
        if (starts-with($collection, "/")) then
            $collection
        else
            repo:get-root() || $collection
    let $repoConf := deploy:repo-descriptor($target)
    let $permissions := deploy:target-permissions($repoConf)
    let $userData := deploy:check-user($repoConf)
    return
        if (not($collection)) then
            error(QName("http://exist-db.org/xquery/sandbox", "missing-collection"), "collection parameter missing")
        else
            let $create := deploy:create-collection($collection, $userData, $permissions)
            let $null := (
                deploy:store-expath($collection, $userData, $permissions),
                deploy:store-repo($repoConf, $collection, $userData, $permissions),
                if (empty($expathConf)) then (
                    deploy:store-templates($collection, $userData, $permissions),
                    deploy:store-libs($collection, $userData, $permissions),
                    deploy:store-ant($collection, $permissions),
                    deploy:expand-xql($collection)
                ) else
                    (),
                deploy:init-simple($collection, $userData, $permissions)
            )
            return
                $collection
};

declare function deploy:create-app($collection as xs:string?, $target as xs:string, $expathConf as element()?) {
    let $collection := deploy:store($collection, $target, $expathConf)
    return
        if (empty($expathConf)) then
            let $expathConf := doc($collection || "/expath-pkg.xml")/*
            return (
                deploy:deploy($collection, $expathConf),
                $collection
            )
        else
            $collection
};

declare function deploy:package($collection as xs:string, $expathConf as element()) {
    let $name := concat($expathConf/@abbrev, "-", $expathConf/@version, ".xar")
    let $xar := compression:zip(xs:anyURI($collection), true(), $collection)
    let $mkcol := deploy:mkcol("/db/system/repo", (), ())
    return
        xmldb:store("/db/system/repo", $name, $xar, "application/zip")
};

declare function deploy:deploy($collection as xs:string, $expathConf as element()) {
    let $pkg := deploy:package($collection, $expathConf)
    let $null := (
        repo:remove($expathConf/@name),
        repo:install-and-deploy-from-db($pkg)
    )
    return
        ()
};

declare function deploy:validate() {
    let $uri := request:get-parameter("uri", ())
    return
        if ($uri = repo:list()) then
            map {
                "error": "An app with this URI does already exist",
                "param": "uri"
            }
        else
            let $abbrev := request:get-parameter("abbrev", ())
            return
                if (collection(repo:get-root() || "/" || $abbrev)/*) then
                    map {
                        "error": "There is already an app using this abbreviation",
                        "param": "abbrev"
                    }
                else
                    ()
};

let $abbrev := request:get-parameter("abbrev", ())
let $collection := request:get-parameter("collection", ())
let $errors := deploy:validate()
return
    if (empty($abbrev)) then
        ()
    else if (exists($errors)) then
        $errors
    else
        let $target :=
            if ($collection) then
                $collection
            else
                repo:get-root() || $abbrev
        let $expathConf := if ($target) then xmldb:xcollection($target)/expath:package else ()
        return
        (:    try {:)
                let $target := deploy:create-app($target, $abbrev, $expathConf)
                return
                    map {
                        "target": $target,
                        "abbrev": $abbrev
                    }
        (:    } catch exerr:EXXQDY0003 {:)
        (:        response:set-status-code(403),:)
        (:        <span>You don't have permissions to access or write the application archive.:)
        (:            Please correct the location or log in as a different user.</span>:)
        (:    } catch exerr:EXREPOINSTALL001 {:)
        (:        response:set-status-code(404),:)
        (:        <p>Failed to install application.</p>:)
        (:    }:)
