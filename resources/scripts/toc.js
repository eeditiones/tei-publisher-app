document.addEventListener("DOMContentLoaded", function () {

    // Open details elements in TOC that contain active links
    function openDetailsWithActiveLinks() {
        const toc = document.querySelector('.toc');
        if (!toc) return;

        // Find all details elements that contain an active pb-link
        const detailsWithActive = toc.querySelectorAll('details:has(pb-link.active)');
        detailsWithActive.forEach(details => {
            details.setAttribute('open', '');
        });
    }

    // Attach pb-collapse-open event listeners to pb-link elements in TOC
    function attachCollapseListeners() {
        const toc = document.querySelector('.toc');
        if (!toc) return;

        const pbLinks = toc.querySelectorAll('pb-link');
        pbLinks.forEach(link => {
            link.addEventListener('pb-collapse-open', function () {
                // Find all ancestor details elements and open them
                let current = link.closest('details');
                while (current) {
                    current.setAttribute('open', '');
                    current = current.parentElement?.closest('details');
                }
            });
        });
    }

    // Listen for pb-results-received events to handle dynamically loaded TOC content
    pbEvents.subscribe('pb-results-received', 'toc', function () {
        setTimeout(() => {
            openDetailsWithActiveLinks();
            attachCollapseListeners();
        }, 100);
    });
});