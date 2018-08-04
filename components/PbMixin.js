function PbAppState() {

    const url = new URL(window.location.href);

    return parent => class PbMixin extends parent {
        static get properties() {
            return {
                subscribe: {
                    type: String
                },
                subscribeConfig: {
                    type: Object
                },
                emit: {
                    type: String
                },
                emitConfig: {
                    type: Object
                }
            }
        }

        constructor() {
            super();
        }

        subscribeTo(type, listener) {
            let keys = [];
            if (this.subscribeConfig) {
                for (const key in this.subscribeConfig) {
                    this.subscribeConfig[key].forEach(t => {
                        if (t === type) {
                            keys.push(key);
                        }
                    })
                }
            } else if (this.subscribe) {
                keys.push(this.subscribe);
            }
            if (keys.length === 0) {
                document.addEventListener(type, listener);
            } else {
                keys.forEach(key =>
                    document.addEventListener(type, ev => {
                        if (ev.detail && ev.detail.key && ev.detail.key === key) {
                            listener(ev);
                        }
                    })
                );
            }
        }

        emitTo(type, options) {
            let detail = {};
            if (this.emit) {
                detail.key = this.emit;
            } else if (this.emitConfig) {
                detail.key = this.emitConfig[type];
            }
            if (options) {
                for (const opt in options) {
                    if (options.hasOwnProperty(opt)) {
                        detail[opt] = options[opt];
                    }
                }
            }
            const ev = new CustomEvent(type, {
                detail: detail,
                composed: true,
                bubbles: true
            });
            document.dispatchEvent(ev);
        }

        getParameter(name) {
            const params = url.searchParams.getAll(name);
            if (params && params.length > 0) {
                return params[0];
            }
            return null;
        }

        getParameterValues(name) {
            return url.searchParams.getAll(name);
        }

        setParameter(name, value) {
            url.searchParams.set(name, value);
        }

        getUrl() {
            return url;
        }

        pushHistory(msg) {
            history.pushState(null, msg, url.toString());
        }
    }
};
