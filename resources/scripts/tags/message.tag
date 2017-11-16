<message>
    <div ref="modal" class="modal fade" tabindex="-1" style="display: none;">
        <div class="modal-dialog" style="z-index: 1080;">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h4 ref="title" class="modal-title">Action</h4>
                </div>
                <div class="modal-body">
                    <div ref="message" class="message"/>
                </div>
                <div class="modal-footer">
                    <button type="submit" class="btn btn-primary" data-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        show(title, message) {
            message = message || '';
            $(this.refs.title).html(title);
            $(this.refs.message).html(message);
            $(this.refs.modal).modal("show");
        }

        set(title, message) {
            $(this.refs.title).html(title);
            $(this.refs.message).html(message);
        }

        this.on("mount", function() {
            $(this.refs.modal).modal({show: false});
        });
    </script>
</message>
