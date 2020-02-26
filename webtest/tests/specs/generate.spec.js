const Page  = require('../pageobjects/Page');

//require("../util.js");
let assert = require('assert');
let path = require('path');
let fs = require('fs');
let request = require('request');

describe('generate app', () => {

    it('should open generate page', () => {
        Page.openUrl("/exist/apps/tei-publisher/index.html");
        browser.login();

        browser.click("*=Admin");
        Page.waitForVisible("a[href*='generate.html']");
        browser.click("a[href*='generate.html']");
        browser.waitForExist("#form-generate");
    });

    it('should fill out form', () => {
        browser.selectByValue("#app-odd", "dta.odd");
        browser.setValue("#app-name", "http://exist-db.org/apps/foo");
        browser.setValue("#app-abbrev", "foo");
        browser.setValue("#app-title", "Foo App");
        browser.setValue("#app-owner", "test");
        browser.setValue("#app-password", "test");

        browser.click("#form-generate button");
        browser.waitForText("#msg-collection", 60000);

        assert.equal(Page.getElementText("#msg-collection"), "/db/apps/foo");
    });

    it('opens generated app', () => {
        Page.openUrl("/exist/apps/foo");

        assert(browser.isExisting("#documents-panel"));
    });
});

describe('upload data and test', () => {
    before(function() {
        return browser.upload(
            path.join('..', 'data', 'test', 'kant_rvernunft_1781.TEI-P5.xml'),
            "/exist/rest/db/apps/foo/data/kant_rvernunft_1781.TEI-P5.xml"
        )
    });

    it('check uploaded file', () => {
        browser.pause(800);
        browser.refresh();
        browser.waitForExist("a[href*='kant_rvernunft_1781.TEI-P5.xml']");
        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
            .waitForVisible(".tp-document-title-wrapper h5");
        assert.equal(Page.getElementText(".tp-document-title-wrapper h5"), "Critik der reinen Vernunft");
    });

    it("table of contents", () => {
        browser.click(".toc-toggle")
            .waitForExist("#toc li:nth-child(3)");

        browser.click("#toc li:nth-child(3) a[data-toggle='collapse'] span")
            .waitForVisible("a[data-div='3.4.4.8.7']");
        browser.click("a[data-div='3.4.4.8.7']")
            .pause(200);
        browser.waitForText(".content h1");

        assert.equal(Page.getElementText(".content h1"), "Einleitung.");
    });

    it("next page", () => {
        browser.click(".nav-next").pause(200);
        browser.waitForText(".content .tei-corr1");
        assert.equal(Page.getElementText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("previous page", () => {
        browser.click(".nav-prev").pause(200);

        browser.waitForText(".content h1");
        assert.equal(Page.getElementText(".content h1"), "Einleitung.");
    });

    it("reload", () => {
        browser.refresh();

        assert.equal(Page.getElementText(".content h1"), "Einleitung.");
    });

    it("next page", () => {
        browser.click(".nav-next").pause(200);
        browser.waitForText(".content .tei-corr1");
        assert.equal(Page.getElementText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("reload", () => {
        browser.refresh();

        assert.equal(Page.getElementText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("search", () => {
        browser.setValue("#searchPageForm input[name='query']", "urtheile");
        browser.submitForm("#searchPageForm");

        let hits = Page.getElementText("#hit-count");
        assert.equal(hits, 34);

        browser.click("#results tr:nth-child(2) .hi a");
        assert(browser.isExisting("mark"));

        browser.back();

        browser.click("#results tr:nth-child(3) .hi a");
        assert(browser.isExisting("mark"));
    });

    it("start page", () => {
        browser.click("#about a");
        assert(browser.isExisting("a[href*='kant_rvernunft_1781.TEI-P5.xml']"));
    });

    it("should delete document", () => {
        browser.click("li[data-doc*='kant_rvernunft_1781.TEI-P5.xml'] .delete").
            waitForVisible("#confirm");
        browser.click("#confirm-delete");
        browser.pause(300);
        let docs = browser.elements("li[data-doc*='kant_rvernunft_1781.TEI-P5.xml']");
        assert.equal(docs.value.length, 0);
    });

    after(function() {
        return browser.uninstall("http://exist-db.org/apps/foo");
    });
});
