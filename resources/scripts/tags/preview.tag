<preview>
    <div class="panel preview">
        <div class="panel-body" ref="body">
            <iframe ref="iframe"></iframe>
        </div>
    </div>
    
    <script>
    this.doc = TeiPublisher.config.sample.doc;
    this.odd = TeiPublisher.config.odd;
    
    this.on('mount', function() {
        var width = $(this.refs.body).width();
        var height = $(this.refs.body).height();
        this.refs.iframe.width = width;
        this.refs.iframe.height = height;
    });
    
    load() {
        this.refs.iframe.src = this.doc + '?odd=' + this.odd;
    }
    
    setODD(odd) {
        this.odd = odd;
        this.load();
    }
    </script>
    <style>
        .preview {
            height: 600px;
            overflow: scroll;
            font-size: 50%;
        }
        
        .preview .panel-body {
            height: 100%;
        }
    </style>
</preview>