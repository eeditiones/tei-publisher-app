<rendition scope="{ scope }">
    <form class="form-inline">
        <div class="form-group">
            <span>Scope:</span>
            <select class="form-control" onchange="{ updateScope }">
                <option each="{ s in scopes }" selected="{ s === scope }">{ s }</option>
            </select>
            <button type="button" class="btn btn-default" onclick="{ remove }"><i class="material-icons">delete</i></button>
        </div>
    </form>
    <textarea rows="3" onchange="{ updateCSS }">{ css }</textarea>

    <script>
    this.scopes = ["", "before", "after"];

    // this.on("mount", function() {
    //     hljs.highlightBlock(this.refs.code);
    // });

    updateScope(ev) {
        this.scope = $(ev.target).val();
    }

    updateCSS(ev) {
        this.css = $(ev.target).val();
    }

    remove(ev) {
        this.parent.removeRendition(ev.item);
    }

    getData() {
        return {
            scope: this.scope,
            css: this.css
        };
    }

    serialize(indent) {
        var xml = indent + '<outputRendition';
        if (this.scope) {
            xml += ' scope="' + this.scope + '"';
        }
        xml += '>\n';
        xml += this.css;
        xml += '\n' + indent + '</outputRendition>\n';
        return xml;
    }
    </script>
    <style>
        .form-group {
            margin-top: 0;
        }
        textarea {
            width: 100%;
        }
    </style>
</rendition>
