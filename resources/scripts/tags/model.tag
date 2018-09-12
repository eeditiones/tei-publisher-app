<model behaviour="{ behaviour }" predicate="{ predicate }" type="{ type }" output="{ output }" css="{ css }">
    <form class="form-inline">
        <header>
            <div>
                <h4>
                    <paper-icon-button ref="toggle" onclick="{ toggle }" class="model-collapse" icon="expand-more"></paper-icon-button>
                    { type } <span class="behaviour" if="{ type === 'model'}">{ behaviour }</span>
                    <span class="btn-group">
                        <paper-icon-button onclick="{ moveDown }" icon="arrow-downward"></paper-icon-button>
                        <paper-icon-button onclick="{ moveUp }" icon="arrow-upward"></paper-icon-button>
                        <paper-icon-button onclick="{ remove }" icon="delete"></paper-icon-button>
                        <paper-icon-button onclick="{ copy }" icon="content-copy"></paper-icon-button>
                        <paper-icon-button onclick="{ paste }" icon="content-paste" if="{type == 'modelSequence' || type == 'modelGrp'}"></paper-icon-button>
                        <paper-menu-button if="{type == 'modelSequence' || type == 'modelGrp'}">
                            <paper-icon-button icon="add" slot="dropdown-trigger"></paper-icon-button>
                            <paper-listbox slot="dropdown-content">
                                <paper-item onclick="{ addNested }">model</paper-item>
                                <paper-item onclick="{ addNested }">modelSequence</paper-item>
                                <paper-item onclick="{ addNested }">modelGrp</paper-item>
                            </paper-listbox>
                        </paper-menu-button>
                    </span>
                </h4>
                <paper-dropdown-menu label="Output">
                    <paper-listbox ref="output" slot="dropdown-content" attr-for-selected="value">
                        <paper-item each="{ o in outputs }" value="{ o }">{ o }</paper-item>
                    </paper-listbox>
                </paper-dropdown-menu>
            </div>
            <p>{ desc } <span class="predicate" if="{ predicate }">{ predicate }</span></p>
        </header>
        <iron-collapse ref="details" opened="{show}" id="elem-{ ident }" class="details">
            <paper-input ref="desc" value="{ desc }" placeholder="[Document the model]"
                onchange="{ refresh }" label="Description"></paper-input>
            <paper-autocomplete ref="behaviour" if="{ type === 'model' }" text="{ behaviour }" placeholder="[Behaviour]" label="Behaviour"></paper-autocomplete>
            <div class="predicate">
                <label>Predicate</label>
                <code-editor ref="predicate" mode="xquery" code="{ predicate || '' }" callback="{ refresh }"
                    placeholder="[XPath condition: model applies only if matched]"/>
            </div>
            <paper-input ref="css" value="{ css }" placeholder="[Define CSS class name (for external CSS)]"
                label="CSS Class"></paper-input>

            <div class="parameters" if="{type == 'model'}">
                <div class="group">
                    <span class="title">Parameters</span>
                    <paper-icon-button icon="add" onclick="{ addParameter }"></paper-icon-button>
                </div>
                <parameter each="{ parameters }" name="{ this.name }" value="{ this.value }"/>
            </div>

            <div class="renditions" if="{type == 'model'}">
                <div class="group">
                    <div>
                        <span class="title">Renditions</span>
                        <paper-icon-button icon="add" onclick="{ addRendition }"></paper-icon-button>
                    </div>
                    <div class="source">
                        <paper-checkbox checked="{ sourcerend }" ref="sourcerend">Use source rendition</paper-checkbox>
                    </div>
                </div>
                <rendition each="{ renditions }" scope="{ this.scope }" css="{ this.css }" events="{ events }"/>
            </div>
        </iron-collapse>

        <div class="models" if="{type == 'modelSequence' || type == 'modelGrp'}">
            <model each="{ models }" behaviour="{ this.behaviour }" predicate="{ this.predicate }"
                type="{ this.type }" output="{ this.output }" desc="{ this.desc }"
                sourcerend="{ this.sourcerend }"/>
        </div>
    </form>
    <script>
        this.mixin('utils');

        this.id = '_' + Math.random().toString(36).substr(2, 9);

        this.outputs = [
            "",
            "web",
            "print",
            "epub",
            "fo",
            "latex",
            "plain"
        ];
        this.behaviours = [
            "alternate",
            "anchor",
            "block",
            "body",
            "break",
            "cell",
            "cit",
            "document",
            "figure",
            "graphic",
            "heading",
            "inline",
            "link",
            "list",
            "listItem",
            "metadata",
            "note",
            "omit",
            "paragraph",
            "row",
            "section",
            "table",
            "text",
            "title",
            "webcomponent"
        ];

        this.on("mount", function() {
            var self = this;

            this.refs.details.addEventListener("opened-changed", function() {
                var opened = this.refs.details.opened;
                var icon = opened ? 'expand-less' : 'expand-more';
                if (opened) {
                    this.parent.collapseAll(this);
                }
                this.refs.toggle.icon = icon;
                this.refs.predicate.initCodeEditor();
                this.forEachTag('parameter', function(param) {
                    param.show();
                });
                this.forEachTag('rendition', function(rendition) {
                    rendition.show();
                });
            }.bind(this));

            if (this.refs.behaviour) {
                var autocomplete = [];
                this.getBehaviours().forEach(function(behaviour) {
                    autocomplete.push({text: behaviour, value: behaviour});
                });
                this.refs.behaviour.showResultsOnFocus = true;
                this.refs.behaviour.source = autocomplete;

                this.refs.behaviour.addEventListener('autocomplete-blur', this.refresh.bind(this));
            }
            this.refs.output.selected = this.output;
        });

        toggle(ev) {
            this.refs.details.toggle();
        }

        collapse() {
            this.refs.details.hide();
        }

        collapseAll(current) {
            this.forEachTag('model', function(model) {
                if (model == current) {
                    return;
                }
                model.collapse();
            })
        }

        getBehaviours() {
            return this.behaviours;
        }

        getBehaviour() {
            if (this.refs.behaviour) {
                return this.refs.behaviour.text;
            }
        }

        remove(e) {
            e.preventDefault();
            this.parent.removeModel(e.item);
        }

        removeModel(item) {
            var index = this.models.indexOf(item);
            this.updateModel();
            this.models.splice(index, 1);

            this.update();
        }

        moveDown(e) {
            e.preventDefault();
            this.parent.moveModelDown(e.item);
        }

        moveUp(e) {
            e.preventDefault();
            this.parent.moveModelUp(e.item);
        }

        addParameter(e) {
            this.updateModel();
            this.parameters.push({
                name: "",
                value: ""
            });
        }

        removeParameter(item) {
            var index = this.parameters.indexOf(item);
            this.updateModel();
            this.parameters.splice(index, 1);

            this.update();
        }

        addRendition(ev) {
            this.updateModel();
            this.renditions.push({
                scope: null,
                css: ''
            });
        }

        removeRendition(item) {
            var index = this.renditions.indexOf(item);
            this.updateModel();
            this.renditions.splice(index, 1);

            this.update();
        }

        copy(ev) {
            ev.preventDefault();
            this.clipboard.copy(this.getData());
        }

        paste(ev) {
            var data = this.clipboard.paste();
            if (data) {
                this.updateModel();
                this.models.unshift(data);
            }
        }

        addNested(ev) {
            ev.preventDefault();
            var type = ev.target.innerText;
            this.updateModel();
            this.models.unshift({
                behaviour: 'inline',
                predicate: null,
                type: type,
                output: null,
                sourcerend: false,
                models: [],
                parameters: [],
                renditions: [],
                show: true
            });
        }

        getData() {
            this.updateModel();
            return {
                behaviour: this.behaviour,
                predicate: this.predicate,
                desc: this.desc,
                css: this.css,
                sourcerend: this.sourcerend,
                type: this.type,
                output: this.output,
                models: this.models,
                parameters: this.parameters,
                renditions: this.renditions
            };
        }

        updateModel() {
            if (this.refs.behaviour) {
                this.behaviour = this.refs.behaviour.text;
            }
            this.output = this.refs.output.selected;
            this.css = this.refs.css.value;
            this.predicate = this.refs.predicate.get();
            this.desc = this.refs.desc.value;
            this.parameters = this.updateTag('parameter');
            if (this.refs.sourcerend) {
                this.sourcerend = this.refs.sourcerend.checked;
            }
            this.renditions = this.updateTag('rendition');
            this.models = this.updateTag('model');
        }

        refresh() {
            this.updateModel();
            this.update();
        }

        serialize(indent) {
            this.updateModel();
            if (this.type === 'model' && !this.behaviour) {
                return '';
            }
            var xml = indent + '<' + this.type;
            if (this.output) {
                xml += ' output="' + this.output + '"';
            }
            if (this.predicate) {
                xml += ' predicate="' + this.escape(this.predicate) + '"';
            }
            if (this.behaviour) {
                xml += ' behaviour="'+ this.behaviour + '"';
            }
            if (this.css) {
                xml += ' cssClass="' + this.css + '"';
            }
            if (this.sourcerend) {
                xml += ' useSourceRendition="true"';
            }
            var nestedIndent = indent + this.indentString;
            var innerXML = "";
            if (this.desc) {
                innerXML += nestedIndent + '<desc>' + this.desc + '</desc>\n';
            }
            innerXML += this.serializeTag('model', nestedIndent);
            innerXML += this.serializeTag('parameter', nestedIndent);
            innerXML += this.serializeTag('rendition', nestedIndent);

            if (innerXML.length == 0) {
                xml += '/>\n';
            } else {
                xml += '>\n' + innerXML;
                xml += indent + '</' + this.type + '>\n';
            }
            return xml;
        }
    </script>
    <style>
        form {
            margin-bottom: 8px;
        }
        paper-input, paper-autocomplete {
            margin-bottom: 16px;
        }
        .models {
            margin-top: 8px;
        }
        .btn, .btn-group {
            margin-top: 0;
            margin-bottom: 0;
        }
        header {
            background-color: #d1dae0;
        }
        header div {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
        }

        header h4 {
            padding: 4px 8px;
            margin: 0;
        }
        header p {
            padding: 0 16px 4px;
            margin: 0;
            font-size: 85%;
        }
        header .predicate {
            color: #ff5722;
        }
        header .predicate:before {
            content: ' [';
        }
        header .predicate:after {
            content: ']';
        }
        .predicate label {
            display: block;
            font-size: 12px;
            font-weight: 300;
            color: rgb(115, 115, 115);
        }
        .model-collapse {
            color: #000000;
            cursor: pointer;
        }
        .model-collapse:hover {
            text-decoration: none;
        }
        .behaviour {
            color: #ff5722;
        }
        .behaviour:before {
            content: ' [';
        }
        .behaviour:after {
            content: ']';
        }
        .group {
            margin: 0;
            font-size: 16px;
            font-weight: bold;
        }
        .group .title {
            /*text-decoration: underline;*/
        }

        .renditions, .parameters {
            padding-left: 16px;
            border-left: 3px solid #e0e0e0;
        }
        .renditions .group {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
        }
        .predicate .form-control {
            width: 100%;
        }

        .source {
            text-decoration: none;
            margin-bottom: 8px;
        }
    </style>
</model>
