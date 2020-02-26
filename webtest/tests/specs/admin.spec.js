const Page  = require('../pageobjects/Page');

describe('admin functions', () => {
    it('should open index page', () => {
        Page.openUrl("/exist/apps/tei-publisher/index.html");
        browser.login();
    });
    it("should show upload panel and admin menu", () => {
        assert(browser.isExisting("#upload-panel"));
        assert(browser.isExisting("*=Admin"));
    });
    it("should recompile odd", () => {
        assert(browser.isExisting("a.recompile"));
        browser.click("a[href*='source=letter.odd']");

        browser.waitForExist("#messageDialog .errors");
        let errors = browser.elements("#messageDialog .errors .list-group-item-danger");
        assert(errors.value.length == 0);
        let success = browser.elements("#messageDialog .errors .list-group-item-success");
        assert(success.value.length > 0);

        browser.click("#messageDialog button[type='submit']");
        browser.pause(300);
    });

    it('uploads a document', () => {
        return browser.upload(
            path.join('test', 'hegel_phaenomenologie_1807.TEI-P5.xml'),
            "/exist/rest/db/apps/tei-publisher/data/test/hegel_phaenomenologie_1807.TEI-P5.xml"
        );
    });

    it('should have uploaded', () => {
        browser.refresh();

        Page.waitForVisible("a[href*='hegel_phaenomenologie_1807.TEI-P5.xml']");
        browser.click("a[href*='hegel_phaenomenologie_1807.TEI-P5.xml']")
            .waitForVisible(".tp-document-title-wrapper h5");
        assert.equal(Page.getElementText(".tp-document-title-wrapper h5"), "Die Phänomenologie des Geistes");
        browser.back();
    });

    it("should regenerate metadata index", () => {
        browser.click("*=Admin");
        Page.waitForVisible("#reindex");
        browser.click("#reindex");

        Page.waitForVisible("#messageDialog .message", 20000);
        browser.click("#messageDialog button[type='submit']");
        browser.pause(500);
    });
    it("should filter by author", () => {
        browser.setValue("input[name='filter']", "hegel");
        browser.click("#f-btn-search");
        browser.pause(300);
        assert.equal(Page.getElementText("#hit-count"), 1);
    });
    it("should delete document", () => {
        browser.click("li[data-doc*='hegel_phaenomenologie_1807.TEI-P5.xml'] .delete").
            waitForVisible("#confirm");
        browser.click("#confirm-delete");
        browser.pause(300);
        browser.refresh();
        let docs = browser.elements("li[data-doc*='hegel_phaenomenologie_1807.TEI-P5.xml']");
        assert.equal(docs.value.length, 0);
    });
});
