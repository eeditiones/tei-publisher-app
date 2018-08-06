<editor>
    <aside>
        <paper-card heading="Visual ODD Editor">
            <div class="card-content">
                <yield/>
                <h3>
                    <span>{ odd }</span>

                    <div>
                        <edit-source ref="editSource">
                            <paper-icon-button icon="code" title="ODD Source"></paper-icon-button>
                        </edit-source>
                        <paper-icon-button onclick="{ reload }" icon="refresh" title="Refresh"></paper-icon-button>
                        <paper-icon-button onclick="{ save }" icon="save" title="Save"></paper-icon-button>
                    </div>
                </h3>
                <div id="new-element" class="input-group">
                    <paper-input ref="identNew" label="Add Element" always-float-label="always-float-label">
                        <paper-icon-button slot="suffix" onclick="{ addElementSpec }" icon="add"></paper-icon-button>
                    </paper-input>
                </div>

                <div id="jump-to">
                    <paper-autocomplete ref="jumpTo" label="Jump to ..." always-float-label="always-float-label"></paper-autocomplete>
                </div>
            </div>
        </paper-card>
    </aside>
    <section class="specs" ref="specs">
        <paper-card class="metadata">
            <pb-collapse>
                <h4 slot="collapse-trigger" class="panel-title">
                    { title || titleShort || odd || 'Loading ...' }
                </h4>
                <div slot="collapse-content">
                    <paper-input ref="title" name="title" value="{ title }" label="Title" placeholder="[Title of the ODD]"></paper-input>
                    <paper-input ref="titleShort" name="short-title" value="{ titleShort }" label="Short title" placeholder="[Short title for display]"></paper-input>
                    <paper-input ref="source" name="source" value="{ source }" label="Source ODD" placeholder="[ODD to inherit from]"></paper-input>

                    <paper-input ref="namespace" name="namespace" value="{ namespace }" label="Namespace" placeholder="[Default namespace URI (if not TEI)]">
                        <paper-checkbox slot="prefix" ref="useNamespace" title="Check for using a different namespace than TEI"/>
                    </paper-input>
                </div>
            </pb-collapse>
        </paper-card>

        <element-spec id="es_{ this.ident }" each="{ elementSpecs }" ident="{ this.ident }" mode="{ this.mode }"
            model="{ this.models }"></element-spec>
    </section>

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
        $(self.refs.useNamespace).change(function() {
            $(self.refs.namespace).prop("disabled", !this.checked);
        });

        self.refs.jumpTo.addEventListener('autocomplete-selected', self.jumpTo.bind(self));
    });

    load() {
        document.dispatchEvent(new CustomEvent('pb-start-update'));

        this.refs.editSource.setPath(TeiPublisher.config.root + '/' + this.odd);
        $.getJSON("modules/editor.xql?odd=" + this.odd + '&root=' + TeiPublisher.config.root, function(data) {
            self.elementSpecs = data.elementSpecs;
            console.log("element specs: %s", self.elementSpecs.length);
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
            self.updateElementSpecs();
            document.dispatchEvent(new CustomEvent('pb-end-update'));
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

    updateElementSpecs() {
        var specs = this.elementSpecs.map(function(spec) {
            return { text: spec.ident, value: spec.ident };
        });
        this.refs.jumpTo.source = specs;
    }

    collapseAll(current) {
        this.forEachTag('element-spec', function(spec) {
            if (spec.ident === current.ident) {
                return;
            }
            spec.collapse();
        })
    }

    jumpTo(ev) {
        var ident = this.refs.jumpTo.text;
        var target = document.getElementById('es_' + ident);

        this.forEachTag('element-spec', function(spec) {
            if (spec.ident === ident) {
                spec.toggle();
            } else {
                spec.collapse();
            }
        });

        var top = $(target).position().top;
        this.refs.specs.scrollTo(0, top + 60);
        this.refs.jumpTo.clear();
    }

    save(ev) {
        document.dispatchEvent(new CustomEvent('pb-start-update'));

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
                document.dispatchEvent(new CustomEvent('pb-end-update'));
            },
            error: function(xhr, status) {
                alert(status);
                document.dispatchEvent(new CustomEvent('pb-end-update'));
            }
        });
    }
    </script>
</editor>
