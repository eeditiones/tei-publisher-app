require("../util.js");
var assert = require('assert');
var path = require('path');

describe('generate app', function() {
    it('should open generate page', function() {
        browser.url(process.env.WDIO_PROTOCOL + "://" + process.env.WDIO_SERVER + ":" +
            process.env.WDIO_PORT + "/exist/apps/tei-publisher/index.html");
        browser.login();

        browser.click("*=Admin");
        browser.waitForVisible("a[href*='generate.html']");
        browser.click("a[href*='generate.html']");
    });

    it('should fill out form', function() {
        browser.waitForExist("#form-generate");
        browser.selectByValue("#app-odd", "dta.odd");
        browser.setValue("#app-name", "http://exist-db.org/apps/foo");
        browser.setValue("#app-abbrev", "foo");
        browser.setValue("#app-title", "Foo App");
        browser.setValue("#app-owner", "test");
        browser.setValue("#app-password", "test");

        browser.click("#form-generate button[type='submit']");
        browser.waitForVisible("#msg-link");

        assert.equal(browser.getText("#msg-collection"), "/db/apps/foo");
    });

    it('opens generated app', function() {
        browser.url(process.env.WDIO_PROTOCOL + "://" + process.env.WDIO_SERVER + ":" +
            process.env.WDIO_PORT + "/exist/apps/foo");

        assert(browser.isExisting("#documents-panel"));
    });

    it('uploads a document', function() {
        var toUpload = path.join('..', 'data', 'test', 'kant_rvernunft_1781.TEI-P5.xml');
        browser.chooseFile('#fileupload', toUpload);

        browser.waitForExist("a[href*='kant_rvernunft_1781.TEI-P5.xml']");
        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
            .waitForVisible(".col-title h5");
        assert.equal(browser.getText(".col-title h5"), "Critik der reinen Vernunft");
    });

    it("table of contents", function() {
        browser.click(".toc-toggle")
            .waitForExist("#toc ul li");

        browser.click("#toc li:nth-child(3) a")
            .waitForVisible("a[data-div='3.4.4.8.7']");
        browser.click("a[data-div='3.4.4.8.7']")
            .pause(200);
        browser.waitForExist(".content h1");

        assert.equal(browser.getText(".content h1"), "Einleitung.");
    });

    it("next page", function() {
        browser.click(".hidden-xs .nav-next").pause(400);
        browser.waitForExist(".content .tei-corr1");
        assert.equal(browser.getText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("previous page", function() {
        browser.click(".hidden-xs .nav-prev").pause(400);

        browser.waitForExist(".content h1");

        assert.equal(browser.getText(".content h1"), "Einleitung.");
    });

    it("reload", function() {
        browser.refresh();

        assert.equal(browser.getText(".content h1"), "Einleitung.");
    });

    it("next page", function() {
        browser.click(".hidden-xs .nav-next").pause(400);
        browser.waitForExist(".content .tei-corr1");
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

    it("removes package", function() {
        browser.url(process.env.WDIO_PROTOCOL + "://" + process.env.WDIO_SERVER + ":" +
            process.env.WDIO_PORT + "/exist/apps/dashboard");
        browser.pause(500);
        browser.click("#user_label").waitForVisible("input[name='user']");
        browser.setValue("input[name='user']", "admin");
        browser.click("#login-dialog-form .dijitButtonNode")
            .waitForVisible("button[title='Package Manager']");
        browser.click("button[title='Package Manager']")
            .waitForVisible("#inlineApp .packageManager");
        browser.pause(2000);
        browser.moveToObject("li[data-name='http://exist-db.org/apps/foo']")
            .waitForVisible(".deleteApp");
        browser.click("li[data-name='http://exist-db.org/apps/foo'] .deleteApp");
        browser.waitForVisible(".dijitDialogPaneContent div span:nth-child(1)");
        browser.click(".dijitDialogPaneContent div span:nth-child(1)");
        browser.pause(2000);

    });
});
