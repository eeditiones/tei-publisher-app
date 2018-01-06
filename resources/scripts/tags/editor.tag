<editor>
    <div class="col-md-3">
        <div ref="panel" class="panel panel-info">
            <div class="panel-heading">
                Visual ODD Editor <span class="label label-warning pull-right">Beta</span>
            </div>
            <div class="panel-body">
                <yield/>
                <h3>{ odd }</h3>

                <div  class="toolbar">
                    <div class="btn-group">
                        <button class="btn btn-default" onclick="{ reload }"><i class="material-icons">replay</i> Reload</button>
                        <button id="save" class="btn btn-default" onclick="{ save }"><i class="material-icons">done_all</i> Save</button>
                    </div>
                </div>

                <div class="btn-group">
                    <edit-source ref="editSource"><i class="material-icons">code</i> ODD Source</edit-source>
                </div>
                <div id="new-element" class="input-group">
                    <input ref="identNew" type="text" class="form-control" placeholder="Element Name">
                    <span class="input-group-btn">
                        <button class="btn btn-default" type="button" onclick="{ addElementSpec }">
                            <i class="material-icons">add</i> New
                        </button>
                    </span>
                </div>

                <div id="jump-to">
                    <combobox ref="jumpTo" source="{ getElementSpecs }" placeholder="Jump to ..." callback="{ jumpTo }"/>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-9 element-specs">
        <div class="row">
            <div class="col-md-12">
                <div class="panel panel-default">
                <div class="panel-heading" role="tab" id="headingOne">
                    <h4 class="panel-title">
                        <a role="button" data-toggle="collapse" href="#collapseSettings" aria-expanded="true" aria-controls="collapseSettings">
                        { title || titleShort || odd || 'Loading ...' }
                        </a>
                    </h4>
                </div>
                <div id="collapseSettings" class="panel-collapse collapse" role="tabpanel" aria-labelledby="headingOne">
                    <div class="panel-body">
                        <form class="form-horizontal">
                            <div class="form-group">
                                <label class="control-label col-sm-3">Title:</label>
                                <div class="col-sm-9">
                                    <input ref="title" type="text" name="title" value="{ title }" class="form-control"/>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="control-label col-sm-3">Short Title:</label>
                                <div class="col-sm-9">
                                    <input ref="titleShort" type="text" name="short-title" value="{ titleShort }" class="form-control"/>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="control-label col-sm-3">Source:</label>
                                <div class="col-sm-9">
                                    <input ref="source" type="text" name="source" value="{ source }" class="form-control"/>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="control-label col-sm-3">Namespace:</label>
                                <div class="col-sm-9">
                                    <div class="input-group">
                                        <span class="input-group-addon">
                                            <input ref="useNamespace" type="checkbox" aria-label="..." title="Check for using a different namespace than TEI"/>
                                        </span>
                                        <input ref="namespace" type="text" class="form-control" name="namespace" value="{ namespace }" disabled
                                            placeholder="Default namespace URI (if not TEI)"/>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <element-spec id="es_{ this.ident }" each="{ elementSpecs }" ident="{ this.ident }" mode="{ this.mode }"
                    model="{ this.models }"></element-spec>
            </div>
        </div>
    </div>

    <message id="main-modal" ref="dialog"></message>

    <script>
    var self = this;
    this.mixin('utils');

    this.odd = opts.odd;
    this.elementSpecs = [];
    this.namespace = null;
    this.source = null;
    this.title = null;
    this.titleShort = null;

    this.on('mount', function() {
        $(self.refs.panel).affix({ top: 60 });
        $(self.refs.panel).on('affix.bs.affix', function() {
            var width = $(self.refs.panel).width();
            self.refs.panel.style.width = width + 'px';
        });
        $(self.refs.panel).on('affixed-top.bs.affix', function() {
            self.refs.panel.style.width = 'auto';
        });
        $(self.refs.useNamespace).change(function() {
            $(self.refs.namespace).prop("disabled", !this.checked);
        });
    });

    load() {
        this.refs.editSource.setPath(TeiPublisher.config.root + '/' + this.odd);
        $.getJSON("modules/editor.xql?odd=" + this.odd + '&root=' + TeiPublisher.config.root, function(data) {
            self.elementSpecs = data.elementSpecs;
            self.namespace = data.namespace;
            self.source = data.source;
            self.title = data.title;
            self.titleShort = data.titleShort;
            if (self.namespace == null) {
                $(self.refs.useNamespace).prop("checked", false);
                $(self.refs.namespace).prop("disabled", true);
            } else {
                $(self.refs.useNamespace).prop("checked", true);
                $(self.refs.namespace).prop("disabled", false);
            }
            self.update();
        });
    }

    reload(ev) {
        ev.preventUpdate = true;
        this.refs.dialog.confirm('Reload?', 'Are you sure to discard changes and reload?')
            .then(self.load);
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
        $.getJSON("modules/editor.xql", {
            action: "find",
            odd: self.odd,
            root: TeiPublisher.config.root,
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
                models: models,
                show: true
            };
            specs.push(newSpec);
            self.elementSpecs = specs;
            self.update();

            var target = document.getElementById('es_' + ident);
            var top = $(target).position().top;
            window.scrollTo(0, top + 60);
        });
    }

    removeElementSpec(item) {
        this.refs.dialog.confirm('Delete?', 'Are you sure you would like to delete the spec for element "' + item.ident + '"')
            .then(function() {
                var index = self.elementSpecs.indexOf(item);
                self.elementSpecs.splice(index, 1);

                self.update();
        });
    }

    getElementSpecs() {
        return this.elementSpecs.map(function(spec) {
            return spec.ident;
        });
    }

    jumpTo() {
        var ident = this.refs.jumpTo.getData();
        var target = document.getElementById('es_' + ident);
        $(".models.collapse").collapse('hide');

        $(target).find('.models.collapse').collapse('show');
        var top = $(target).position().top;
        window.scrollTo(0, top + 60);
        this.refs.jumpTo.clear();
    }

    save(ev) {
        ev.preventUpdate = true;

        var useNamespace = this.refs.useNamespace.checked;
        if (useNamespace) {
            this.namespace = this.refs.namespace.value;
        }
        this.source = this.refs.source.value;
        this.title = this.refs.title.value;
        this.titleShort = this.refs.titleShort.value;

        var specs = '<schemaSpec xmlns="http://www.tei-c.org/ns/1.0"';
        if (useNamespace) {
            specs += ' ns="' + this.namespace + '"';
        }
        if (this.source) {
            specs += ' source="' + this.source + '"';
        }
        specs += '>\n';

        specs += '<title>' + this.title + '</title>\n';
        specs += '<title type="short">' + this.titleShort + '</title>\n';

        this.elementSpecs = this.updateTag('element-spec');
        specs += this.serializeTag('element-spec', this.indentString.repeat(4));
        specs += '</schemaSpec>';

        this.refs.dialog.show("Saving ...");

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
                        msg += '<pre class="list-group-item-text">' + report.error + '</pre>';
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
