function PbAppState() {

    const url = new URL(window.location.href);

    return parent => class PbMixin extends parent {
        static get properties() {
            return {
                /**
                 * The channel to subscribe to. Only events on a channel corresponding
                 * to this property are listened to.
                 */
                subscribe: {
                    type: String
                },
                /**
                 * Configuration object to define a channel/event mapping. Every property
                 * in the object is interpreted as the name of a channel and its value should
                 * be an array of event names to listen to.
                 */
                subscribeConfig: {
                    type: Object
                },
                /**
                 * The channel to send events to.
                 */
                emit: {
                    type: String
                },
                /**
                 * Configuration object to define a channel/event mapping. Every property
                 * in the object is interpreted as the name of a channel and its value should
                 * be an array of event names to be dispatched.
                 */
                emitConfig: {
                    type: Object
                }
            }
        }

        constructor() {
            super();
        }


        /**
         * Listen to the event defined by type. If property `subscribe` or `subscribe-config`
         * is defined, this method will trigger the listener only if the event has a key
         * equal to the key defined in `subscribe` or `subscribe-config`.
         */
        subscribeTo(type, listener) {
            let channels = [];
            if (this.subscribeConfig) {
                for (const key in this.subscribeConfig) {
                    this.subscribeConfig[key].forEach(t => {
                        if (t === type) {
                            channels.push(key);
                        }
                    })
                }
            } else if (this.subscribe) {
                channels.push(this.subscribe);
            }
            if (channels.length === 0) {
                // no channel defined: listen for all events not targetted at a channel
                document.addEventListener(type, ev => {
                    if (ev.detail && ev.detail.key) {
                        return;
                    }
                    listener(ev);
                });
            } else {
                channels.forEach(key =>
                    document.addEventListener(type, ev => {
                        if (ev.detail && ev.detail.key && ev.detail.key === key) {
                            listener(ev);
                        }
                    })
                );
            }
        }

        /**
         * Dispatch an event of the given type, optionally limited to listeners on
         * a certain channel, defined by properties `emit` or `emit-config`.
         */
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
