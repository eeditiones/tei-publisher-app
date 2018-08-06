<odd-select>
    <paper-dropdown-menu label="Editing ODD:">
        <paper-listbox ref="select" name="odd" slot="dropdown-content" attr-for-selected="value">
            <yield/>
        </paper-listbox>
    </paper-dropdown-menu>

    <script>
        var self = this;
        var historySupport = !!(window.history && window.history.pushState);

        selected(ev) {
            var odd = this.refs.select.selected;
            if (this.odd === odd) {
                return;
            }
            this.odd = odd;
            console.log("Selected odd %s", odd);
            // if (historySupport) {
            //     var state = TeiPublisher.config;
            //     state.odd = odd;
            //     var url = window.location.pathname + '?' + $.param(state);
            //     history.pushState(state, null, url);
            // }
            this.parent.setODD(odd);
        }

        this.on("mount", function() {
            self.refs.select.selected = TeiPublisher.config.odd;
            self.refs.select.addEventListener('selected-item-changed', self.selected.bind(self));
            this.selected();

            // $(window).on("popstate", function(ev) {
            //     var state = ev.originalEvent.state;
            //     console.log("popstate: %s", state.odd);
            //     self.refs.select.value = state.odd;
            //     self.parent.setODD(state.odd);
            // });
        });
    </script>
    <style>
        paper-dropdown-menu {
            width: 100%;
        }
    </style>
</odd-select>
