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
                history.pushState(null, null, window.location.pathname + '?odd=' + odd);
            }
            this.parent.setODD(odd);
        }
        
        this.on("mount", function() {
            this.selected();
            
            $(window).on("popstate", function(ev) {
                var odd = window.location.search.replace(/^.*odd=([^&]+)/, "$1");
                console.log("popstate: %s", odd);
                $(self.refs.select).val(odd);
                self.parent.setODD(odd);
            });
        });
    </script>
    <style>
        .form-group {
            margin-top: 0;
        }
    </style>
</odd-select>
