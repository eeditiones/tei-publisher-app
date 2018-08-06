<message type="{ type }">
    <paper-dialog ref="modal">
        <h2 ref="title">Action</h2>
        <paper-dialog-scrollable ref="message" class="message"></paper-dialog-scrollable>
        <div class="buttons">

            <paper-button dialog-confirm="dialog-confirm" autofocus="autofocus" if="{ this.type == 'message' }">Close</paper-button>
            <paper-button ref="confirm" dialog-confirm="dialog-confirm" autofocus="autofocus" if="{ this.type == 'confirm' }">Yes</paper-button>
            <paper-button dialog-confirm="dialog-confirm" autofocus="autofocus" if="{ this.type == 'confirm' }">No</paper-button>
        </div>
    </paper-dialog>

    <script>
        this.type = this.opts.type;

        show(title, message) {
            this.type = 'message';
            message = message || '';
            this.update();
            $(this.refs.title).html(title);
            $(this.refs.message).html(message);
            this.refs.modal.open();
        }

        confirm(title, message) {
            this.type = 'confirm';
            this.set(title, message);
            this.update();
            this.refs.modal.open();

            return new Promise(function(resolve, reject) {
                $(this.refs.confirm).one('click', resolve);
            }.bind(this));
        }

        set(title, message) {
            $(this.refs.title).html(title);
            $(this.refs.message).html(message);
        }
    </script>
    <style>
        paper-dialog {
            min-width: 420px;
            max-width: 640px;
            min-height: 128px;
        }

        paper-dialog h2 {
            background-color: #607D8B;
        }
    </style>
</message>
