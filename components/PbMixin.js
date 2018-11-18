if (!window.TeiPublisher) {
    window.TeiPublisher = {};
    
    TeiPublisher.url = new URL(window.location.href);
}

/**
 * Implements the core channel/event mechanism used by components in TEI Publisher
 * to communicate.
 *
 * As there might be several documents/fragments being displayed on a page at the same time,
 * a simple event mechanism is not enough for components to exchange messages. They need to
 * be able to target a specific view. The mechanism implemented by this mixin thus combines
 * events and channels. Components may emit an event into a named channel to which other
 * components might subscribe. For example, there might be a view which subscribes to the
 * channel *transcription* and another one subscribing to *translation*. By using distinct
 * channels, other components can address only one of the two.
 *
 * @polymer
 * @mixinFunction
 */
PbMixin = Polymer.dedupingMixin((superclass) => 

/**
 * @polymer
 * @mixinClass
 */
class PbMixin extends superclass {
    static get properties() {
        return {
            /**
             * The name of the channel to subscribe to. Only events on a channel corresponding
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
             * The name of the channel to send events to.
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
     *
     * @param {String} type Name of the event, usually starting with `pb-`
     * @param {Function} listener Callback function
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
            document.addEventListener(type, (ev) => {
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
     * Dispatch an event of the given type. If the properties `emit` or `emit-config`
     * are defined, the event will be limited to the channel specified there.
     *
     * @param {String} type Name of the event, usually starting with `pb-`
     * @param {Object} options Options to be passed in ev.detail
     */
    emitTo(type, options) {
        const channels = [];
        if (this.emitConfig) {
            for (const key in this.emitConfig) {
                this.emitConfig[key].forEach(t => {
                    if (t === type) {
                        channels.push(key);
                    }
                })
            }
        } else if (this.emit) {
            channels.push(this.emit);
        }
        if (channels.length == 0) {
            const ev = new CustomEvent(type, {
                detail: options,
                composed: true,
                bubbles: true
            });
            document.dispatchEvent(ev);
        } else {
            channels.forEach(key => {
                const detail = {
                    key: key
                };
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
            });
        }
    }

    getParameter(name, fallback) {
        const params = TeiPublisher.url.searchParams.getAll(name);
        if (params && params.length > 0) {
            return params[0];
        }
        return fallback;
    }

    getParameterValues(name) {
        return TeiPublisher.url.searchParams.getAll(name);
    }

    setParameter(name, value) {
        TeiPublisher.url.searchParams.set(name, value);
    }

    getUrl() {
        return TeiPublisher.url;
    }

    pushHistory(msg, state) {
        history.pushState(state, msg, TeiPublisher.url.toString());
    }
});