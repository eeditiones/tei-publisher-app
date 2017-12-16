<message type="{ type }">
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
                    <button if="{ this.type == 'message' }" type="submit" class="btn btn-primary" data-dismiss="modal">Close</button>
                    <button if="{ this.type == 'confirm' }" type="submit" class="btn btn-primary" data-dismiss="modal" ref="confirm">Yes</button>
                    <button if="{ this.type == 'confirm' }" type="submit" class="btn btn-primary" data-dismiss="modal">No</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        this.type = this.opts.type;
        
        show(title, message) {
            this.type = 'message';
            message = message || '';
            this.update();
            $(this.refs.title).html(title);
            $(this.refs.message).html(message);
            $(this.refs.modal).modal("show");
        }

        confirm(title, message) {
            this.type = 'confirm';
            this.set(title, message);
            this.update();
            $(this.refs.modal).modal("show");
            return new Promise(function(resolve, reject) {
                $(this.refs.confirm).one('click', resolve);
            }.bind(this));
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
