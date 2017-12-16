<model behaviour="{ behaviour }" predicate="{ predicate }" type="{ type }" output="{ output }" css="{ css }">
    <form class="form-inline">
        <header>
            <h4>
                <div class="pull-right">
                    <label>Output:</label>
                    <select ref="output" class="form-control">
                        <option each="{ o in outputs }" selected="{ o === output }">{ o }</option>
                    </select>
                </div>
                <a data-toggle="collapse" data-target="#{ id }" class="model-collapse">
                    <i class="material-icons" ref="collapseToggle">expand_more</i>
                    { type } <span class="behaviour" if="{ type === 'model'}">{ behaviour }</span>
                </a>
                <div class="btn-group">
                    <button type="button" class="btn btn-default" onclick="{ moveDown }"><i class="material-icons">arrow_downward</i></button>
                    <button type="button" class="btn btn-default" onclick="{ moveUp }"><i class="material-icons">arrow_upward</i></button>
                    <button type="button" class="btn btn-default" onclick="{ remove }"><i class="material-icons">delete</i></button>
                    <div class="btn-group" if="{type == 'modelSequence' || type == 'modelGrp'}">
                        <button type="button" class="btn dropdown-toggle" data-toggle="dropdown"><i class="material-icons">add</i></button>
                        <ul class="dropdown-menu">
                            <li><a href="#" onclick="{ addNested }">model</a></li>
                            <li><a href="#" onclick="{ addNested }">modelSequence</a></li>
                            <li><a href="#" onclick="{ addNested }">modelGrp</a></li>
                        </ul>
                    </div>
                </div>
            </h4>
            <p>{ desc } <span class="predicate" if="{ predicate }">{ predicate }</span></p>
        </header>
        <div class="collapse details { show ? 'in' : '' }" id="{ id }" ref="details">
            <table>
                <tr class="predicate">
                    <td>Description:</td>
                    <td><input ref="desc" type="text" class="form-control" value="{ desc }" placeholder="[Document the model]" onchange="{ refresh }"/></td>
                </tr>
                <tr if="{ type === 'model' }">
                    <td>Behaviour:</td>
                    <td>
                        <combobox ref="behaviour" current="{ behaviour }" source="{ getBehaviours }" callback="{ refresh }"
                            placeholder="[behaviour]"/>
                    </td>
                </tr>
                <tr class="predicate">
                    <td>Predicate:</td>
                    <td>
                        <code-editor ref="predicate" mode="xquery" code="{ predicate || '' }" callback="{ refresh }"
                            placeholder="[XPath condition: model applies only if matched]"/>
                    </td>
                </tr>
                <tr class="predicate">
                    <td>CSS Class:</td>
                    <td>
                        <input ref="css" type="text" class="form-control" value="{ css }"
                            placeholder="[Define CSS class name (for external CSS)]"/>
                    </td>
                </tr>
            </table>

            <div class="parameters" if="{type == 'model'}">
                <div class="group"><span class="title">Parameters</span> <button type="button" class="btn" onclick="{ addParameter }"><i class="material-icons">add</i></button></div>
                <parameter each="{ parameters }" name="{ this.name }" value="{ this.value }"/>
            </div>

            <div class="renditions" if="{type == 'model'}">
                <div class="group"><span class="title">Renditions</span>
                    <button type="button" class="btn" onclick="{ addRendition }"><i class="material-icons">add</i></button>
                    <span class="source"><input type="checkbox" checked="{ sourcerend }" ref="sourcerend"/> Use source rendition</span>
                </div>
                <rendition each="{ renditions }" scope="{ this.scope }" css="{ this.css }" events="{ events }"/>
            </div>
        </div>

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
            "title"
        ];

        this.on("mount", function() {
            var self = this;
            $(this.refs.details).on("show.bs.collapse", function() {
                $('.details').collapse('hide');
                $(self.refs.collapseToggle).text("expand_less");
            });
            $(this.refs.details).on("hide.bs.collapse", function() {
                $(self.refs.collapseToggle).text("expand_more");
            });

        });

        getBehaviours() {
            return this.behaviours;
        }

        getBehaviour() {
            if (this.refs.behaviour) {
                return this.refs.behaviour.getData();
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

        addNested(ev) {
            ev.preventDefault();
            var type = $(ev.target).text();
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
                this.behaviour = this.refs.behaviour.getData();
            }
            this.output = this.refs.output.options[this.refs.output.selectedIndex].value;
            this.css = this.refs.css.value;
            this.predicate = this.refs.predicate.get();
            this.desc = this.refs.desc.value;
            this.parameters = this.updateTag('parameter');
            this.sourcerend = $(this.refs.sourcerend).is(":checked");
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

        table {
            width: 100%;
        }
        td {
            padding-bottom: 10px;
        }
        td > * {
            width: 100%;
        }
        td:nth-child(1) {
            width: 20%;
            font-weight: bold;
            padding-right: 10px;
        }
        .parameters {
            display: table;
            width: 100%;
        }
        .predicate .form-control {
            width: 100%;
        }

        .source {
            text-decoration: none;
        }
        .source input {
            margin-bottom: 8px;
            margin-right: 1em;
        }
    </style>
</model>
