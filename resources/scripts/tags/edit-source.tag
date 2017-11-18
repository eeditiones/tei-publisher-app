<edit-source>
    <a class="btn btn-default" target="eXide" data-exide-open="{ path }"
        href="../eXide/index.html?open={path}" onclick="{ click }"><yield/></a>
    <script>
        setPath(path) {
            this.path = path;
        }

        click(ev) {
            // try to retrieve existing eXide window
            var exide = window.open("", "eXide");
            if (exide && !exide.closed) {
                var snip = $(this).data("exide-create");
                var path = this.path;

                // check if eXide is really available or it's an empty page
                var app = exide.eXide;
                if (app) {
                    // eXide is there
                    if (snip) {
                        exide.eXide.app.newDocument(snip, "xquery");
                    } else {
                        console.log("Locating document %s", path);
                        exide.eXide.app.findDocument(path);
                    }
                    exide.focus();
                    setTimeout(function() {
                        if ($.browser.msie ||
                            (typeof exide.eXide.app.hasFocus == "function" && !exide.eXide.app.hasFocus())) {
                            alert("Opened code in existing eXide window.");
                        }
                    }, 200);
                } else {
                    window.eXide_onload = function() {
                        console.log("onload called for %s", path);
                        if (snip) {
                            exide.eXide.app.newDocument(snip, "xquery");
                        } else {
                            exide.eXide.app.findDocument(path);
                        }
                    };
                    // empty page
                    console.log("Opening %s", ev.target.href.substring(0, ev.target.href.indexOf('?')));
                    exide.location = ev.target.href.substring(0, ev.target.href.indexOf('?'));
                }
                ev.preventDefault();
            }
            return true;
        }
    </script>
</edit-source>
