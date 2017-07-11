require("../util.js");
var assert = require('assert');
var path = require('path');

describe('browsing text', function() {

    it('open document', function() {
        browser.url("/exist/apps/tei-publisher/doc/documentation.xml");

        browser.waitForText(".tp-document-title-wrapper h5");
        assert.equal(browser.getText(".tp-document-title-wrapper h5"), "TEI Publisher");
    });

    it('navigates forward', function() {
        while (browser.isVisible(".nav-next")) {
            var next = browser.getAttribute(".nav-next", "data-root");
            browser.url("/exist/apps/tei-publisher/doc/documentation.xml?odd=documentation.odd&view=div&root=" + next);
            browser.waitForVisible(".tp-document-title-wrapper h5");
            assert.equal(browser.getText(".tp-document-title-wrapper h5"), "TEI Publisher");
        }
    });

    it('navigates backward', function() {
        while (browser.isVisible(".nav-prev")) {
            var next = browser.getAttribute(".nav-prev", "data-root");
            browser.url("/exist/apps/tei-publisher/doc/documentation.xml?odd=documentation.odd&view=div&root=" + next);
            browser.waitForVisible(".tp-document-title-wrapper h5");
            assert.equal(browser.getText(".tp-document-title-wrapper h5"), "TEI Publisher");
        }
    });
});
