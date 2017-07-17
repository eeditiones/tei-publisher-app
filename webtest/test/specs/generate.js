require("../util.js");
var assert = require('assert');
var path = require('path');
var fs = require('fs');
var request = require('request');

describe('generate app', function() {

    it('should open generate page', function() {
        browser.url("/exist/apps/tei-publisher/index.html");
        browser.login();

        browser.click("*=Admin");
        browser.waitForVisible("a[href*='generate.html']");
        browser.click("a[href*='generate.html']");
        browser.waitForExist("#form-generate");
    });

    it('should fill out form', function() {
        browser.selectByValue("#app-odd", "dta.odd");
        browser.setValue("#app-name", "http://exist-db.org/apps/foo");
        browser.setValue("#app-abbrev", "foo");
        browser.setValue("#app-title", "Foo App");
        browser.setValue("#app-owner", "test");
        browser.setValue("#app-password", "test");

        browser.click("#form-generate button");
        browser.waitForText("#msg-collection", 60000);

        assert.equal(browser.getText("#msg-collection"), "/db/apps/foo");
    });

    it('opens generated app', function() {
        browser.url("/exist/apps/foo");

        assert(browser.isExisting("#documents-panel"));
    });
});

describe('upload data and test', function() {
    before(function() {
        return browser.upload(
            path.join('..', 'data', 'test', 'kant_rvernunft_1781.TEI-P5.xml'),
            "/exist/rest/db/apps/foo/data/kant_rvernunft_1781.TEI-P5.xml"
        )
    });

    it('check uploaded file', function() {
        browser.pause(800);
        browser.refresh();
        browser.waitForExist("a[href*='kant_rvernunft_1781.TEI-P5.xml']");
        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
            .waitForVisible(".tp-document-title-wrapper h5");
        assert.equal(browser.getText(".tp-document-title-wrapper h5"), "Critik der reinen Vernunft");
    });

    it("table of contents", function() {
        browser.click(".toc-toggle")
            .waitForExist("#toc li:nth-child(3)");

        browser.click("#toc li:nth-child(3) a[data-toggle='collapse'] span")
            .waitForVisible("a[data-div='3.4.4.8.7']");
        browser.click("a[data-div='3.4.4.8.7']")
            .pause(200);
        browser.waitForText(".content h1");

        assert.equal(browser.getText(".content h1"), "Einleitung.");
    });

    it("next page", function() {
        browser.click(".nav-next").pause(200);
        browser.waitForText(".content .tei-corr1");
        assert.equal(browser.getText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("previous page", function() {
        browser.click(".nav-prev").pause(200);

        browser.waitForText(".content .tei-fw4");
        assert.equal(browser.getText(".content .tei-fw4"), "wird");
    });

    it("reload", function() {
        browser.refresh();

        assert.equal(browser.getText(".content .tei-fw4"), "wird");
    });

    it("next page", function() {
        browser.click(".nav-next").pause(200);
        browser.waitForText(".content .tei-corr1");
        assert.equal(browser.getText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("reload", function() {
        browser.refresh();

        assert.equal(browser.getText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("search", function() {
        browser.setValue("#searchPageForm input[name='query']", "urtheile");
        browser.submitForm("#searchPageForm");

        var hits = browser.getText("#hit-count");
        assert.equal(hits, 26);

        browser.click("#results tr:nth-child(2) .hi a");
        assert(browser.isExisting("mark"));

        browser.back();

        browser.click("#results tr:nth-child(3) .hi a");
        assert(browser.isExisting("mark"));
    });

    it("start page", function() {
        browser.click("#about a");
        assert(browser.isExisting("a[href*='kant_rvernunft_1781.TEI-P5.xml']"));
    });

    it("should delete document", function() {
        browser.click("li[data-doc*='kant_rvernunft_1781.TEI-P5.xml'] .delete").
            waitForVisible("#confirm");
        browser.click("#confirm-delete");
        browser.pause(300);
        var docs = browser.elements("li[data-doc*='kant_rvernunft_1781.TEI-P5.xml']");
        assert.equal(docs.value.length, 0);
    });

    after(function() {
        return browser.uninstall("http://exist-db.org/apps/foo");
    });
});
