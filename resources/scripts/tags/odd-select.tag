<odd-select>
    <form class="form form-horizontal col-md-12">
        <div class="form-group">
            <label for="odd-select" class="control-label">Editing ODD:</label>
            <select ref="select" id="odd-select" class="form-control" name="odd" onchange="{ selected }">
                <yield/>
            </select>
        </div>
    </form>
    <script>
        var self = this;
        var historySupport = !!(window.history && window.history.pushState);

        selected(ev) {
            var odd = $(this.refs.select).val();
            if (historySupport) {
                var state = TeiPublisher.config;
                state.odd = odd;
                var url = window.location.pathname + '?' + $.param(state);
                history.pushState(state, null, url);
            }
            this.parent.setODD(odd);
        }

        this.on("mount", function() {
            this.selected();

            $(window).on("popstate", function(ev) {
                var state = ev.originalEvent.state;
                console.log("popstate: %s", state.odd);
                $(self.refs.select).val(state.odd);
                self.parent.setODD(state.odd);
            });
        });
    </script>
    <style>
        .form-group {
            margin-top: 0;
        }
    </style>
</odd-select>
