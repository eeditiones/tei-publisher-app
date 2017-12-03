<combobox>
    <div class="dropdown">
        <input ref="value" class="form-control" type="text" value="{ current }" data-toggle="dropdown"
            onkeyup="{ filter }" onfocus="{ filter }" placeholder="{ opts.placeholder }" onchange="{ changed }"/>
        <ul class="dropdown-menu">
            <li each="{ o in this.options }" onclick="{ selected }">{ o }</li>
        </ul>
    </div>
    <script>

        this.current = opts.current;
        this.source = opts.source;
        this.callback = opts.callback;
        this.options = this.source();

        getData() {
            return this.refs.value.value;
        }

        filter(ev) {
            var val = ev.target.value;
            if (val) {
                this.options = this.source().filter(function(option) {
                    return option.indexOf(val) > -1;
                });
            } else {
                this.options = this.source();
            }
        }

        selected(ev) {
            this.current = $(ev.target).text();
            this.refs.value.value = this.current;
            if (this.callback) {
                this.callback();
            }
        }
        
        changed(ev) {
            if (this.callback) {
                this.callback();
            }
        }

        reset(ev) {
            this.options = this.source();
        }
    </script>
    <style>
        li:hover {
            cursor: pointer;
            background-color: #C0C0C0;
        }
    </style>
</combobox>
