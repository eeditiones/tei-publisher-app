<rendition scope="{ scope }">
    <form class="form-inline">
        <div class="form-group">
            <span>Scope:</span>
            <select ref="scope" class="form-control">
                <option each="{ s in scopes }" selected="{ s === scope }">{ s }</option>
            </select>
            <button type="button" class="btn btn-default" onclick="{ remove }"><i class="material-icons">delete</i></button>
        </div>
    </form>
    <code-editor ref="css" mode="css" code="{ this.css }"></code-editor>

    <script>
    this.mixin('utils');

    var self = this;

    this.scopes = ["", "before", "after"];

    remove(ev) {
        this.parent.removeRendition(ev.item);
    }

    getData() {
        return {
            scope: $(this.refs.scope).val(),
            css: this.refs.css.get()
        };
    }

    serialize(indent) {
        var scope = $(this.refs.scope).val();
        var xml = indent + '<outputRendition';
        if (scope) {
            xml += ' scope="' + scope + '"';
        }
        xml += '>\n';
        xml += indent + this.indentString + this.refs.css.get();
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
