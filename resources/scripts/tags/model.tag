<model behaviour="{ behaviour }" predicate="{ predicate }" type="{ type }" output="{ output }">
    <h4>
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
                <select class="form-control" onchange="{ updateBehaviour }">
                    <option each="{ b in behaviours }" selected="{ b === behaviour }">{ b }</option>
                </select>
            </td>
        </tr>
        <tr>
            <td>Predicate:</td>
            <td>
                <input class="inline-edit" type="text" value="{ predicate }" onchange="{ updatePredicate }"/>
            </td>
        </tr>
        <tr>
            <td>Output:</td>
            <td>
            <select class="form-control" onchange="{ updateOutput }">
                <option each="{ o in outputs }" selected="{ o === output }">{ o }</option>
            </select>
            </td>
        </tr>
    </table>

    <div class="parameters" if="{type == 'model'}">
        <h5>Parameters <button type="button" class="btn" onclick="{ addParameter }"><i class="material-icons">add</i></button></h5>
        <parameter each="{ parameters }" name="{ this.name }" value="{ this.value }"/>
    </div>

    <div class="renditions" if="{type == 'model'}">
        <h5>Renditions <button type="button" class="btn" onclick="{ addRendition }"><i class="material-icons">add</i></button></h5>
        <rendition each="{ renditions }" scope="{ this.scope }" css="{ this.css }"/>
    </div>

    <div class="models" if="{type == 'modelSequence'}">
        <h5>Nested Models
            <div class="btn-group">
                <button type="button" class="btn dropdown-toggle" data-toggle="dropdown"><i class="material-icons">add</i></button>
                <ul class="dropdown-menu">
                    <li><a href="#" onclick="{ addModel }">model</a></li>
                    <li><a href="#" onclick="{ addModel }">modelSequence</a></li>
                    <li><a href="#" onclick="{ addModel }">modelGrp</a></li>
                </ul>
            </div>
        </h5>
        <model each="{ models }" behaviour="{ this.behaviour }" predicate="{ this.predicate }"
            type="{ this.type }" output="{ this.output }"/>
    </div>

    <script>
        this.mixin('utils');

        this.outputs = [
            "",
            "web",
            "pdf",
            "epub",
            "fo",
            "latex"
        ];
        this.behaviours = [
            "",
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

        updateBehaviour(e) {
            this.behaviour = $(e.target).val();
        }

        updateOutput(e) {
            this.output = $(e.target).val();
        }

        updatePredicate(e) {
            this.predicate = $(e.target).val();
        }

        remove(e) {
            e.preventDefault();
            this.parent.removeModel(e.item);
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
            this.parameters = this.updateTag('parameter');
            this.parameters.push({
                name: "",
                value: ""
            });
        }

        removeParameter(item) {
            this.parameters = this.parameters.filter(function(param) {
                return param.name !== item.name;
            });
            this.update();
        }

        addRendition(ev) {
            this.renditions = this.updateTag('rendition');

            this.renditions.push({
                scope: null,
                css: ''
            });
        }

        addNested(ev) {
            var type = $(ev.target).text();
            this.models = this.updateTag('model');
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
            return {
                behaviour: this.behaviour,
                predicate: this.predicate,
                type: this.type,
                output: this.output,
                models: this.updateTag('model'),
                parameters: this.updateTag('parameter'),
                renditions: this.updateTag('rendition')
            };
        }

        serialize(indent) {
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
            xml += '>\n';

            xml += this.serializeTag('model', indent);
            xml += this.serializeTag('parameter', indent);
            xml += this.serializeTag('rendition', indent);

            xml += indent + '</' + this.type + '>\n';
            return xml;
        }
    </script>
    <style>
        h5 {
            margin: 0;
            font-size: 16px;
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
    </style>
</model>
