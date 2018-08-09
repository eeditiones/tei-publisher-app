<rendition scope="{ scope }">
    <paper-dropdown-menu label="Scope">
        <paper-listbox ref="scope" slot="dropdown-content" selected="{ scope }" attr-for-selected="value">
            <option each="{ s in scopes }" value="{ s }">{ s }</option>
        </paper-listbox>
    </paper-dropdown-menu>
    <paper-icon-button onclick="{ remove }" icon="delete"></paper-icon-button>
    <code-editor ref="css" mode="css" code="{ this.css }" placeholder="[CSS to apply]"></code-editor>

    <script>
    this.mixin('utils');

    var self = this;

    this.scopes = ["", "before", "after"];

    remove(ev) {
        this.parent.removeRendition(ev.item);
    }

    getData() {
        return {
            scope: this.refs.scope.selected,
            css: this.refs.css.get()
        };
    }

    serialize(indent) {
        var css = this.refs.css.get();
        if (!css) {
            return '';
        }
        css = this.escape(css);
        
        var scope = this.refs.scope.selected;
        var xml = indent + '<outputRendition';
        if (scope) {
            xml += ' scope="' + scope + '"';
        }
        xml += '>\n';
        xml += indent + this.indentString + css;
        xml += '\n' + indent + '</outputRendition>\n';
        return xml;
    }
    
    show() {
        this.refs.css.initCodeEditor();
    }
    </script>
    <style>
        code-editor {
            margin-top: 10px;
        }
    </style>
</rendition>
