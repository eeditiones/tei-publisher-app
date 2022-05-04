xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

<div>
    <h3>Test form setting parameter `foo` to be sent to `pb-browse-docs`</h3>
    <input name="foo" value="bar"/>
    <button type="submit">Submit</button>
</div>