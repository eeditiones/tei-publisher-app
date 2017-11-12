function Mixin() {
    this.updateTag = function(name) {
        var data = [];
        this.forEachTag(name, function(tag) {
            data.push(tag.getData());
        });
        return data;
    }

    this.forEachTag = function(name, callback) {
        if (this.tags[name]) {
            if (this.tags[name].length) {
                this.tags[name].forEach(function(tag) {
                    callback(tag);
                });
            } else {
                callback(this.tags);
            }
        }
    }

    this.serializeTag = function(name, indent) {
        indent = indent || '';
        if (this.tags[name]) {
            if (this.tags[name].length) {
                var xml = "";
                this.tags[name].forEach(function(tag) {
                    xml += tag.serialize(indent + "    ");
                });
                return xml;
            } else {
                return this.tags[name].serialize(indent + "    ");
            }
        }
        return "";
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
}
