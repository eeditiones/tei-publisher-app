document.addEventListener('DOMContentLoaded', function() {
    const element = document.querySelector('.banner-spacer');

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) {
                element.classList.add('not-visible');
            } else {
                element.classList.remove('not-visible');
            }
        });
    }, {
        threshold: 0,
        rootMargin: '-95px 0px 0% 0px'
    });

    observer.observe(element);
});