<parameter name="{ name }" value="{ value }">
    <combobox ref="combo" class="name" current="{ name }" source="{ updateList }" onchange="{ updateName }"/>
    <span class="value">
        <textarea class="form-control" rows="3" value="{ value }" onchange="{ updateValue }"/>
    </span>
    <span class="actions">
        <button type="button" class="btn btn-default" onclick="{ delete }"><i class="material-icons">delete</i></button>
    </span>

    <script>
    var self = this;

    updateList() {
        return parameters[this.parent.behaviour] || [];
    }

    updateName(ev) {
        this.name = $(ev.target).val();
    }

    updateValue(ev) {
        this.value = $(ev.target).val();
    }

    delete(ev) {
        ev.preventDefault();
        this.parent.removeParameter(ev.item);
    }

    getData() {
        return {
            name: this.name,
            value: this.value
        };
    }

    serialize(indent) {
        return indent + '<param name="' + this.name + '" value="' + this.value + '"/>\n';
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
