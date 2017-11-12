<editor>
    <div class="col-md-3">
        <div class="panel panel-info">
            <div class="panel-heading">
                Edit ODD
            </div>
            <div class="panel-body">
                <yield/>
                <h3>{ odd }</h3>

                <div class="btn-group">
                    <button class="btn btn-default" onclick="{ load }"><i class="material-icons">replay</i> Reload</button>
                    <button class="btn btn-default" onclick="{ save }"><i class="material-icons">done_all</i> Save</button>
                </div>

                <div class="input-group">
                    <input ref="identNew" type="text" class="form-control" placeholder="Element Name">
                    <span class="input-group-btn">
                        <button class="btn btn-default" type="button" onclick="{ addElementSpec }">
                            <i class="material-icons">add</i> New Element
                        </button>
                    </span>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-9">
        <element-spec each="{ elementSpecs }" ident="{ this.ident }" mode="{ this.mode }"
            model="{ this.models }"></element-spec>
    </div>

    <message ref="dialog"></message>

    <script>
    this.odd = opts.odd;
    this.elementSpecs = [];

    load() {
        var self = this;
        $.getJSON("modules/editor.xql?odd=" + this.odd, function(data) {
            self.elementSpecs = data;
            self.update();
        });
    }

    setODD(odd) {
        this.odd = odd;
        this.load();
    }

    addElementSpec(ev) {
        var ident = this.refs.identNew.value;
        this.elementSpecs.push({
            ident: ident,
            mode: "change",
            models: []
        });
    }

    removeElementSpec(item) {
        var index = this.elementSpecs.indexOf(item);
        this.elementSpecs.splice(index, 1);

        this.update();
    }

    save(ev) {
        ev.preventUpdate = true;

        var specs = ['<schemaSpec xmlns="http://www.tei-c.org/ns/1.0">\n'];
        var tags = this.tags['element-spec'];
        if (tags.length) {
            tags.forEach(function(tag) {
                specs.push(tag.serialize());
            });
        } else {
            specs.push(tags.serialize());
        }
        specs.push('</schemaSpec>');

        var self = this;
        $.ajax({
            method: "post",
            dataType: "json",
            url: "modules/editor.xql",
            data: {
                action: "save",
                odd: this.odd,
                data: specs.join('')
            },
            success: function(data) {
                self.refs.dialog.show("Saved", data.report);
            },
            error: function(xhr, status) {
                alert(status);
            }
        });
    }
    </script>
</editor>
