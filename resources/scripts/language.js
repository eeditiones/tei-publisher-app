window.addEventListener('DOMContentLoaded', () => {
    pbEvents.subscribe('pb-i18n-language', null, (ev) => {
        const { language } = ev.detail;
        window.location.href = `?lang=${language}`;
    });
});