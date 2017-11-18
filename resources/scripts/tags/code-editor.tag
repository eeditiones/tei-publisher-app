<code-editor>
    <pre ref="code" onclick="{ initCodeEditor }" class="{ mode }">{ this.code }</pre>

    <script>
    this.mixin('utils');
    var self = this;

    this.code = opts.code;
    this.mode = opts.mode;

    this.app.on('show', function() {
        self.initCodeEditor();
    });

    this.on('mount', function() {
        self.initCodeEditor();
    });

    initCodeEditor() {
        if (this.codemirror || !$(this.refs.code).is(":visible")) {
            return;
        }
        this.codemirror = CodeMirror(function(elt) {
            self.refs.code.style.display = 'none';
            self.refs.code.parentNode.appendChild(elt);
        }, {
            value: self.code,
            mode: self.mode,
            lineNumbers: false,
            lineWrapping: true,
            autofocus: false,
            theme: "ttcn"
        });
    }

    get() {
        if (this.codemirror) {
            return this.codemirror.getValue();
        }
        return this.code;
    }
    </script>
</code-editor>
