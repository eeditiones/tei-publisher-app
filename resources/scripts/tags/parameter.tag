<parameter name="{ name }" value="{ value }">
    <input class="name inline-edit" type="text" value="{ name }" onchange="{ updateName }"/>
    <input class="value inline-edit" type="text" value="{ value }" onchange="{ updateValue }"/>
    <span class="actions">
        <button type="button" class="btn btn-default" onclick="{ delete }"><i class="material-icons">delete</i></button>
    </span>

    <script>
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
    <style>
    :scope { display: table-row; }
    input { display: table-cell; }
    .actions { display: table-cell; width: 10%; }
    .btn { margin: 0; }
    .value { width: 70%; padding-left: 10px; }
    .name { width: 20%; font-weight: bold; }
    </style>
</parameter>
