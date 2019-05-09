(:
 :
 :  Copyright (C) 2019 Wolfgang Meier
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

declare namespace expath="http://expath.org/ns/pkg";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

let $xar := compression:zip(xs:anyURI($config:app-root), true(), $config:app-root)
let $name := config:expath-descriptor()/@abbrev
return
    response:stream-binary($xar, "media-type=application/zip", $name || ".xar")