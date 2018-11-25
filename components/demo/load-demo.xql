xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../../modules/lib/pages.xql";

let $doc := request:get-parameter("doc", ())
let $document := pages:get-document($doc)
return
    <aside>
        <h2>Parameters passed to pb-load</h2>
        <table>
            <tr>
                <th>Parameter</th>
                <th>Value</th>
            </tr>
        {
            for $param in request:get-parameter-names()
            return
                <tr>
                    <td>{$param}</td>
                    <td>{request:get-parameter($param, ())}</td>
                </tr>
        }
        </table>
        <h2>Actors in the play</h2>
        <ul>
        {
            for $speaker in $document//tei:listPerson/tei:person
            return
                <li>{$speaker/tei:persName[@type="standard"]/string()}</li>
        }
        </ul>
    </aside>
