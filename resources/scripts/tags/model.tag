<model behaviour="{ behaviour }" predicate="{ predicate }" type="{ type }" output="{ output }" class="{ class }">
    <form class="form-inline">
        <h4>
            <div class="pull-right">
                <label>Output:</label>
                <select ref="output" class="form-control">
                    <option each="{ o in outputs }" selected="{ o === output }">{ o }</option>
                </select>
            </div>
            { type }
            <div class="btn-group">
                <button type="button" class="btn btn-default" onclick="{ moveDown }"><i class="material-icons">arrow_downward</i></button>
                <button type="button" class="btn btn-default" onclick="{ moveUp }"><i class="material-icons">arrow_upward</i></button>
                <button type="button" class="btn btn-default" onclick="{ remove }"><i class="material-icons">delete</i></button>
            </div>
        </h4>
        <table>
            <tr if="{ type === 'model' }">
                <td>Behaviour:</td>
                <td>
                    <combobox ref="behaviour" current="{ behaviour }" source="{ getBehaviours }"/>
                </td>
            </tr>
            <tr class="predicate">
                <td>Predicate:</td>
                <td>
                    <input ref="predicate" type="text" class="form-control" value="{ predicate }"/>
                </td>
            </tr>
            <tr class="predicate">
                <td>CSS Class:</td>
                <td>
                    <input ref="class" type="text" class="form-control" value="{ class }"/>
                </td>
            </tr>
        </table>

        <div class="parameters" if="{type == 'model'}">
            <div class="group">Parameters <button type="button" class="btn" onclick="{ addParameter }"><i class="material-icons">add</i></button></div>
            <parameter each="{ parameters }" name="{ this.name }" value="{ this.value }"/>
        </div>

        <div class="renditions" if="{type == 'model'}">
            <div class="group">Renditions <button type="button" class="btn" onclick="{ addRendition }"><i class="material-icons">add</i></button></div>
            <rendition each="{ renditions }" scope="{ this.scope }" css="{ this.css }"/>
        </div>

        <div class="models" if="{type == 'modelSequence' || type == 'modelGrp'}">
            <div class="group">Nested Models
                <div class="btn-group">
                    <button type="button" class="btn dropdown-toggle" data-toggle="dropdown"><i class="material-icons">add</i></button>
                    <ul class="dropdown-menu">
                        <li><a href="#" onclick="{ addNested }">model</a></li>
                        <li><a href="#" onclick="{ addNested }">modelSequence</a></li>
                        <li><a href="#" onclick="{ addNested }">modelGrp</a></li>
                    </ul>
                </div>
            </div>
            <model each="{ models }" behaviour="{ this.behaviour }" predicate="{ this.predicate }"
                type="{ this.type }" output="{ this.output }"/>
        </div>
    </form>
    <script>
        this.mixin('utils');

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
            var type = $(ev.target).text();
            this.updateModel();
            this.models.unshift({
                behaviour: 'inline',
                predicate: null,
                type: type,
                output: null,
                models: [],
                parameters: [],
                renditions: []
            });
        }

        getData() {
            this.updateModel();
            return {
                behaviour: this.behaviour,
                predicate: this.predicate,
                class: this.class,
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
            this.class = this.refs.class.value;
            this.predicate = this.refs.predicate.value;
            this.parameters = this.updateTag('parameter');
            this.renditions = this.updateTag('rendition');
            this.models = this.updateTag('model');
        }

        serialize(indent) {
            this.updateModel();
            var xml = indent + '<' + this.type;
            if (this.behaviour) {
                xml += ' behaviour="'+ this.behaviour + '"';
            }
            if (this.predicate) {
                xml += ' predicate="' + this.predicate + '"';
            }
            if (this.output) {
                xml += ' output="' + this.output + '"';
            }
            if (this.class) {
                xml += ' cssClass="' + this.class + '"';
            }
            xml += '>\n';

            xml += this.serializeTag('model', indent);
            xml += this.serializeTag('parameter', indent);
            xml += this.serializeTag('rendition', indent);

            xml += indent + '</' + this.type + '>\n';
            return xml;
        }
    </script>
    <style>
        h4 {
            padding: 4px 8px;
            background-color: #d1dae0;
        }
        .group {
            margin: 0;
            font-size: 16px;
            font-weight: bold;
            text-decoration: underline;
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
    </style>
</model>
