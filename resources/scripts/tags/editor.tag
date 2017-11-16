<editor>
    <div class="col-md-3">
        <div class="panel panel-info">
            <div class="panel-heading">
                Visual ODD Editor
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
    this.mixin('utils');
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
        if (!ident || ident.length == 0) {
            return;
        }
        var self = this;
        $.getJSON("modules/editor.xql", {
            action: "find",
            odd: self.odd,
            ident: ident
        }, function(data) {
            var mode;
            var models = [];
            if (data.status === 'not-found') {
                mode = 'add';
            } else {
                mode = 'change';
                models = data.models;
            }

            self.elementSpecs = self.updateTag('element-spec');
            var newSpec = {
                ident: ident,
                mode: mode,
                models: models
            };
            self.elementSpecs.push(newSpec);
            console.log(self.elementSpecs);
            self.update();
        });
    }

    removeElementSpec(item) {
        var index = this.elementSpecs.indexOf(item);
        this.elementSpecs.splice(index, 1);

        this.update();
    }

    save(ev) {
        ev.preventUpdate = true;

        this.elementSpecs = this.updateTag('element-spec');
        var specs = ['<schemaSpec xmlns="http://www.tei-c.org/ns/1.0">\n'];
        var tags = this.tags['element-spec'];
        if (tags) {
            if (tags.length) {
                tags.forEach(function(tag) {
                    specs.push(tag.serialize());
                });
            } else {
                specs.push(tags.serialize());
            }
        }
        specs.push('</schemaSpec>');

        this.refs.dialog.show("Saving ...");

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
                var msg = '<div class="list-group">';
                data.report.forEach(function(report) {
                    if (report.error) {
                        msg += '<div class="list-group-item-danger">';
                        msg += '<h4 class="list-group-item-heading">' + report.file + '</h4>';
                        msg += '<h5 class="list-group-item-heading">Compilation error on line ' + report.line + ':</h5>'
                        msg += '<pre class="list-group-item-text">' + report.message + '</pre>';
                        msg += '</div>';
                    } else {
                        msg += '<div class="list-group-item-success">';
                        msg += '<p class="list-group-item-text">Generated '+ report.file + '</p>';
                        msg += '</div>';
                    }
                });
                msg += '</div>';
                self.refs.dialog.set("Saved", msg);
            },
            error: function(xhr, status) {
                alert(status);
            }
        });
    }
    </script>
</editor>
