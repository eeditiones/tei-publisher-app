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
        selected(ev) {
            this.parent.setODD($(this.refs.select).val());
        }
        this.on("mount", function() {
            this.selected();
        });
    </script>
    <style>
        .form-group {
            margin-top: 0;
        }
    </style>
</odd-select>
