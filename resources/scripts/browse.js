document.addEventListener('DOMContentLoaded', function () {

    /* Scan for links to collections and handle clicks */
    function handleCollectionLinks(root) {
        root.querySelectorAll('[data-collection]').forEach((link) => {
            link.addEventListener('click', (ev) => {
                ev.preventDefault();

                const collection = link.getAttribute('data-collection');
                // write the collection into a hidden input and resubmit the search
                document.querySelector('.options [name=collection]').value = collection;
                pbEvents.emit('pb-search-resubmit', 'search');
            });
        });
    }

    pbEvents.subscribe('pb-collection', 'search', function(ev) {
        const { collection } = ev.detail;

        const breadcrumbs = document.querySelector('.toolbar [aria-label="breadcrumb"] ul');
        breadcrumbs.innerHTML = '';

        // Tokenize the collection path and create breadcrumb navigation
        const pathComponents = collection.split('/').filter(component => component.length > 0);

        const li = document.createElement('li');
        const a = document.createElement('a');
        a.href = '?collection=';
        const i18n = document.createElement('pb-i18n');
        i18n.setAttribute('key', 'breadcrumb.collection-root');
        i18n.textContent = 'Home';
        a.appendChild(i18n);
        li.appendChild(a);

        breadcrumbs.appendChild(li);

        let currentPath = '';

        pathComponents.forEach((component, index) => {
            if (index > 0) {
                currentPath += '/';
            }
            currentPath += component;

            const li = document.createElement('li');
            const a = document.createElement('a');
            a.href = `?collection=${encodeURIComponent(currentPath)}`;
            const i18n = document.createElement('pb-i18n');
            i18n.setAttribute('key', 'breadcrumb.' + currentPath.replaceAll('/', '.'));
            i18n.textContent = component;
            a.appendChild(i18n);
            li.appendChild(a);

            breadcrumbs.appendChild(li);
        });
    });

    let loginCount = 0;
    pbEvents.subscribe('pb-login', null, function(ev) {
        if (ev.detail.userChanged && loginCount > 0) {
            pbEvents.emit('pb-search-resubmit', 'search');
            ++loginCount;
        }
    });

    handleCollectionLinks(document);

    /* Parse the content received from the server */
    pbEvents.subscribe('pb-results-received', 'search', function(ev) {
        const { content } = ev.detail;
        /* Check if the server passed an element containing the current
           collection in attribute data-root */
        const root = content.querySelector('[data-root]');
        const currentCollection = root ? root.getAttribute('data-root') : "";
        const writable = root ? root.classList.contains('writable') : false;

        /* Report the current collection and if it is writable.
           This is relevant for e.g. the pb-upload component */
        pbEvents.emit('pb-collection', 'search', {
            writable,
            collection: currentCollection
        });
        /* hide any element on the page which has attribute can-write */
        document.querySelectorAll('[can-write]').forEach((elem) => {
            elem.disabled = !writable;
        });
        handleCollectionLinks(content);
    });
});
