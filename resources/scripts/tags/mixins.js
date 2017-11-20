function Mixin(app) {
    this.app = app;

    this.indentString = '    ';

    var replaceChars = {
        '"': '&quot;',
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;'
    };
    
    CodeMirror.registerHelper("lint", "xquery", lintXQuery);

    this.escape = function(code) {
        var regex = new RegExp(Object.keys(replaceChars).join("|"), "g"); 
        return code.replace(regex, function(match) {
            return replaceChars[match];
        });
    }
    
    this.updateTag = function(name) {
        var data = [];
        this.forEachTag(name, function(tag) {
            data.push(tag.getData());
        });
        return data;
    }

    this.forEachTag = function(name, callback) {
        if (this.tags && this.tags[name]) {
            if (this.tags[name].length) {
                this.tags[name].forEach(function(tag) {
                    callback(tag);
                });
            } else {
                callback(this.tags[name]);
            }
        }
    }

    this.serializeTag = function(name, indent) {
        indent = indent || '';
        var xml = "";
        this.forEachTag(name, function(tag) {
            xml += tag.serialize(indent);
        });
        return xml;
    }

    this.moveModelDown = function(item) {
        var index = this.models.indexOf(item);
        if (index == this.models.length - 1) {
            return;
        }
        this.models = this.updateTag('model');
        var m = [];
        for (var i = 0; i < this.models.length; i++) {
            if (i == index) {
                m.push(this.models[i + 1]);
                m.push(this.models[i]);
                i++;
            } else {
                m.push(this.models[i]);
            }
        }
        this.models = m;
        this.update();
    }

    this.moveModelUp = function(item) {
        var index = this.models.indexOf(item);
        if (index == 0) {
            return;
        }
        this.models = this.updateTag('model');
        var m = [];
        for (var i = 0; i < this.models.length; i++) {
            if (i == index - 1) {
                m.push(this.models[index]);
                m.push(this.models[i]);
            } else if (i != index){
                m.push(this.models[i]);
            }
        }
        this.models = m;
        this.update();
    }

    function lintXQuery(text) {
        if (!text) {
            return [];
        }
        return new Promise(function(resolve, reject) {
            $.getJSON("modules/editor.xql", {
                action: "lint",
                code: text
            }, function(data) {
                if (data.status === 'fail') {
                    resolve([{
                        message: data.message,
                        severity: "error",
                        from: CodeMirror.Pos(data.line - 1, data.column),
                        to: CodeMirror.Pos(data.line - 1, data.column + 1)
                    }]);
                } else {
                    resolve([]);
                }
            });
        });
    }
}
