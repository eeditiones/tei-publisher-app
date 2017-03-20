require("../util.js");
var assert = require('assert');
var path = require('path');

describe('browsing text', function() {
    
    it('open document', function() {
        browser.url("/exist/apps/tei-publisher/doc/documentation.xml");

        browser.waitForText(".col-title h5");
        assert.equal(browser.getText(".col-title h5"), "TEI Publisher");
    });
    
    it('navigates forward', function() {
        while (browser.isVisible(".hidden-xs .nav-next")) {
            var next = browser.getAttribute(".hidden-xs .nav-next", "data-root");
            browser.url("/exist/apps/tei-publisher/doc/documentation.xml?odd=documentation.odd&view=div&root=" + next);
            browser.waitForVisible(".col-title h5");
            assert.equal(browser.getText(".col-title h5"), "TEI Publisher");
        }
    });
    
    it('navigates backward', function() {
        while (browser.isVisible(".hidden-xs .nav-prev")) {
            var next = browser.getAttribute(".hidden-xs .nav-prev", "data-root");
            browser.url("/exist/apps/tei-publisher/doc/documentation.xml?odd=documentation.odd&view=div&root=" + next);
            browser.waitForVisible(".col-title h5");
            assert.equal(browser.getText(".col-title h5"), "TEI Publisher");
        }
    });
});