<editor>
    <div class="col-md-3">
        <div ref="panel" class="panel panel-info" data-spy="affix" data-offset-top="60" data-offset-bottom="200">
            <div class="panel-heading">
                Visual ODD Editor <span class="label label-warning pull-right">Beta</span>
            </div>
            <div class="panel-body">
                <yield/>
                <h3>{ odd }</h3>

                <div  class="toolbar">
                    <div class="btn-group">
                        <button class="btn btn-default" onclick="{ load }"><i class="material-icons">replay</i> Reload</button>
                        <button class="btn btn-default" onclick="{ save }"><i class="material-icons">done_all</i> Save</button>
                    </div>
                </div>

                <div class="btn-group">
                    <edit-source ref="editSource"><i class="material-icons">code</i> ODD Source</edit-source>
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
    var self = this;
    this.mixin('utils');

    this.odd = opts.odd;
    this.elementSpecs = [];

    this.on('mount', function() {
        $(self.refs.panel).on('affix.bs.affix', function() {
            var width = $(self.refs.panel).width();
            self.refs.panel.style.width = width + 'px';
        });
        $(self.refs.panel).on('affixed-top.bs.affix', function() {
            self.refs.panel.style.width = 'auto';
        });
    });

    load() {
        var self = this;
        this.refs.editSource.setPath(TeiPublisher.config.root + '/' + this.odd);
        $.getJSON("modules/editor.xql?odd=" + this.odd + '&root=' + TeiPublisher.config.root, function(data) {
            self.elementSpecs = data;
            self.update();
        });
    }

    setODD(odd) {
        this.odd = odd;
        this.load();
    }

    addElementSpec(ev) {
        ev.preventUpdate = true;
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

            var specs = self.updateTag('element-spec');
            var newSpec = {
                ident: ident,
                mode: mode,
                models: models
            };
            specs.push(newSpec);
            self.elementSpecs = specs;
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

        var specs = '<schemaSpec xmlns="http://www.tei-c.org/ns/1.0">\n';
        this.elementSpecs = this.updateTag('element-spec');
        specs += this.serializeTag('element-spec');
        specs += '</schemaSpec>';

        this.refs.dialog.show("Saving ...");

        var self = this;
        $.ajax({
            method: "post",
            dataType: "json",
            url: "modules/editor.xql",
            data: {
                action: "save",
                root: TeiPublisher.config.root,
                "output-prefix": TeiPublisher.config.outputPrefix,
                "output-root": TeiPublisher.config.outputRoot,
                odd: this.odd,
                data: specs
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
