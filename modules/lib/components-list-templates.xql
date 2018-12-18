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

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

array {
    for $html in collection($config:app-root || "/templates/pages")/*
    let $description := $html//meta[@name="description"]/@content/string()
    return
        map {
            "name": util:document-name($html),
            "title": $description
        }
}
