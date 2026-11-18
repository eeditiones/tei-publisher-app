/** Primary language subtag only (e.g. en-US → en). */
function primaryLang(language) {
    if (!language || typeof language !== 'string') return language;
    return language.split('-')[0].toLowerCase();
}

/**
 * Remember the chosen language in a cookie, so the server (page:resolve-language)
 * renders the next page in that language even if the link carries no `lang` parameter.
 * The cookie is scoped to the app (pb-page app-root) and kept for a year.
 */
function storeLang(lang) {
    const primary = primaryLang(lang);
    if (!primary) return;
    const page = document.querySelector('pb-page');
    const root = (page && (page.getAttribute('app-root') || page.getAttribute('endpoint'))) || '/';
    const path = root.replace(/\/+$/, '') || '/';
    document.cookie = `lang=${encodeURIComponent(primary)}; path=${path}; max-age=31536000; SameSite=Lax`;
}

/** Same URL with `lang` set; keeps path, other query params, and hash. */
function locationWithLang(lang) {
    const url = new URL(window.location.href);
    url.searchParams.set('lang', primaryLang(lang));
    return url.href;
}

window.addEventListener('DOMContentLoaded', () => {
    // an explicit ?lang=… (e.g. from a shared link) also becomes the stored preference
    const langParam = new URL(window.location.href).searchParams.get('lang');
    if (langParam) {
        storeLang(langParam);
    }

    pbEvents.subscribe('pb-i18n-language', null, (ev) => {
        const { language } = ev.detail;
        storeLang(language);
        window.location.href = locationWithLang(language);
    });

    // at initialization time, compare the language retrieved from parameters and context with what is reported
    // by i18n. Reload the page if they differ.
    let languageDefault;
    const languageDefaultEl = document.getElementById('language-default');
    if (languageDefaultEl?.textContent?.trim()) {
        try {
            languageDefault = JSON.parse(languageDefaultEl.textContent).language;
        } catch {
            /* missing or invalid JSON */
        }
    }
    if (!languageDefault) {
        return;
    }
    pbEvents.subscribe('pb-page-ready', null, (ev) => {
        const { language } = ev.detail;
        if (language && primaryLang(language) !== primaryLang(languageDefault)) {
            storeLang(language);
            window.location.href = locationWithLang(language);
        }
    });
});