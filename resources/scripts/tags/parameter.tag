<parameter name="{ name }" value="{ value }">
    <paper-autocomplete ref="combo" text="{ name }" placeholder="[Param name]" label="Name" source="[]"></paper-autocomplete>
    <span class="value">
        <code-editor ref="value" mode="xquery" code="{ value }" placeholder="[XPath to define param value]"></code-editor>
    </span>
    <span class="actions">
        <paper-icon-button onclick="{ delete }" icon="delete"></paper-icon-button>
    </span>

    <script>
    this.mixin('utils');

    this.on("mount", function() {
        this.show();
        this.updateList();
    });

    updateList() {
        var autocomplete = [];
        var values = parameters[this.parent.getBehaviour()] || [];

        values.forEach(function(val) {
            autocomplete.push({
                text: val, value: val
            });
        });
        this.refs.combo.source = autocomplete;
    }

    delete(ev) {
        ev.preventDefault();
        this.parent.removeParameter(ev.item);
    }

    getData() {
        return {
            name: this.refs.combo.text,
            value: this.refs.value.get()
        };
    }

    serialize(indent) {
        var name = this.refs.combo.text;
        if (!name) {
            return '';
        }
        return indent + '<param name="' + name + '" value="' + this.escape(this.refs.value.get()) + '"/>\n';
    }

    show() {
        this.refs.value.initCodeEditor();
    }
    
    var parameters = {
        alternate: ["content", "default", "alternate"],
        anchor: ["content", "id"],
        block: ["content"],
        body: ["content"],
        break: ["content", "type"],
        cell: ["content"],
        cit: ["content", "source"],
        "document": ["content"],
        figure: ["content", "title"],
        graphic: ["content", "url", "width", "height", "scale", "title"],
        heading: ["content", "level"],
        inline: ["content"],
        link: ["content", "link"],
        list: ["content"],
        listItem: ["content"],
        metadata: ["content"],
        note: ["content", "place", "label"],
        omit: ["content"],
        paragraph: ["content"],
        row: ["content"],
        section: ["content"],
        table: ["content"],
        text: ["content"],
        title: ["content"]
    };
    <style>
    :scope { display: flex; flex-direction: row; align-items: flex-start; }
    paper-autocomplete { flex: 1 0; margin-right: 10px; }
    .actions {  }
    .btn { margin: 0; }
    .value { flex: 2 0; padding-left: 10px; min-width: 300px; min-height: 1em; }
    </style>
</parameter>
