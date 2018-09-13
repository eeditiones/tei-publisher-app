require("../util.js");
var assert = require('assert');
var path = require('path');
var testIndex = "/exist/apps/tei-publisher/components/test/index.html";

describe('wct test index', function() {
    before(function() {
        browser.url(testIndex);
    });

    it("must contain a div with id 'mocha'", function() {
        assert(browser.isExisting("div#mocha"));
    });
});
