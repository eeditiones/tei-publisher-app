<parameter name="{ name }" value="{ value }">
    <combobox ref="combo" class="name" current="{ name }" source="{ updateList }" placeholder="[Param name]"/>
    <span class="value">
        <code-editor ref="value" mode="xquery" code="{ value }" placeholder="[XPath to define param value]"></code-editor>
    </span>
    <span class="actions">
        <button type="button" class="btn btn-default" onclick="{ delete }"><i class="material-icons">delete</i></button>
    </span>

    <script>
    this.mixin('utils');

    updateList() {
        return parameters[this.parent.getBehaviour()] || [];
    }

    delete(ev) {
        ev.preventDefault();
        this.parent.removeParameter(ev.item);
    }

    getData() {
        return {
            name: this.refs.combo.getData(),
            value: this.refs.value.get()
        };
    }

    serialize(indent) {
        var name = this.refs.combo.getData();
        if (!name) {
            return '';
        }
        return indent + '<param name="' + name + '" value="' + this.escapeXPath(this.refs.value.get()) + '"/>\n';
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
    :scope { display: table-row; }
    input { display: table-cell; margin-right: 10px; }
    .actions { display: table-cell; width: 10%; }
    .btn { margin: 0; }
    .value { display: table-cell; width: 70% !important; padding-left: 10px; }
    textarea { width: 100% !important; }
    combobox { display: table-cell; width: 20% !important; font-weight: bold; vertical-align: bottom; }
    </style>
</parameter>
