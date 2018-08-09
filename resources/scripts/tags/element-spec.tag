<element-spec ident="{ ident }" mode="{ mode }">
    <h3>
        <paper-icon-button ref="toggle" icon="expand-more" if="{ models.length > 0 }" onclick="{ toggle }"></paper-icon-button>
        { ident }
        <paper-menu-button>
            <paper-icon-button icon="add" slot="dropdown-trigger"></paper-icon-button>
            <paper-listbox slot="dropdown-content">
                <paper-item onclick="{ addModel }">model</paper-item>
                <paper-item onclick="{ addModel }">modelSequence</paper-item>
                <paper-item onclick="{ addModel }">modelGrp</paper-item>
            </paper-listbox>
        </paper-menu-button>

        <paper-icon-button onclick="{ remove }" icon="delete"></paper-icon-button>
        <paper-icon-button onclick="{ paste }" icon="content-paste"></paper-icon-button>
    </h3>

    <iron-collapse ref="models" class="models" opened="{show}" id="elem-{ ident }">
        <model each="{ models }" behaviour="{ this.behaviour }" predicate="{ this.predicate }"
            type="{ this.type }" output="{ this.output }" css="{ this.css }" models="{ this.models }"
            parameters="{ this.parameters }" desc="{ this.desc }"
            sourcerend="{ this.sourcerend }"/>
    </iron-collapse>

    <script>
        this.mixin('utils');

        this.on("mount", function() {
            var self = this;

            this.refs.models.addEventListener("opened-changed", function() {
                var opened = this.refs.models.opened;
                var icon = opened ? 'expand-less' : 'expand-more';
                if (this.refs.toggle) {
                    this.refs.toggle.icon = icon;
                }
                if (opened) {
                    this.parent.collapseAll(this);
                }
            }.bind(this));
        });

        toggle(ev) {
            this.refs.models.toggle();
        }

        collapse() {
            this.refs.models.hide();
        }

        collapseAll(current) {
            this.forEachTag('model', function(model) {
                if (model == current) {
                    return;
                }
                model.collapse();
            })
        }

        addModel(ev) {
            ev.preventDefault();
            var type = ev.target.innerText;

            this.models = this.updateTag('model');

            this.refs.models.show();

            this.models.unshift({
                behaviour: 'inline',
                predicate: null,
                type: type,
                output: null,
                models: [],
                parameters: [],
                renditions: [],
                sourcerend: false,
                show: true
            });
        }

        removeModel(item) {
            this.parent.refs.dialog.confirm('Delete?', 'Are you sure to delete the model?')
                .then(function() {
                    var index = this.models.indexOf(item);
                    this.models = this.updateTag('model');
                    this.models.splice(index, 1);

                    this.update();
                }.bind(this)
            );
        }

        remove(ev) {
            this.parent.removeElementSpec(ev.item);
        }

        paste(ev) {
            var data = this.clipboard.paste();
            if (data) {
                this.models = this.updateTag('model');
                this.refs.models.open();
                this.models.unshift(data);
            }
        }

        getData() {
            return {
                ident: this.ident,
                mode: this.mode,
                models: this.updateTag('model')
            };
        }

        serialize(indent) {
            var xml = indent + '<elementSpec ident="' + this.ident + '"';
            if (this.mode) {
                xml += ' mode="' + this.mode + '"';
            }
            xml += '>\n';

            xml += this.serializeTag('model', indent + this.indentString);

            xml += indent + '</elementSpec>\n';
            return xml;
        }
    </script>

    <style>
        input { vertical-align: middle; }
    </style>
</element-spec>
