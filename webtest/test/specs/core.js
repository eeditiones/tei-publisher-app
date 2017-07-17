require("../util.js");
var assert = require('assert');
var path = require('path');
var client = require(process.env.WDIO_PROTOCOL);
var sizeOf = require('image-size');

describe('browsing text', function() {

    it('open document', function() {
        browser.url("/exist/apps/tei-publisher/index.html");

        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
        browser.waitForVisible(".tp-document-title-wrapper h5");
        assert.equal(browser.getText(".tp-document-title-wrapper h5"), "Critik der reinen Vernunft");
    });

    it("table of contents", function() {
        browser.click(".toc-toggle")
            .waitForVisible("#toc li:nth-child(3)");

        browser.click("#toc li:nth-child(3) a[data-toggle='collapse'] span")
            .waitForVisible("a[data-div='3.4.4.8.7']");
        browser.click("a[data-div='3.4.4.8.7']");
        browser.waitForText(".content .tei-fw4");

        assert.equal(browser.getText(".content .tei-fw4"), "wird");
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
        browser.click("#searchPageForm .glyphicon-search");

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
});

describe('view image on page', function() {
    var image;
    var requestOptions = {
      hostname: process.env.WDIO_SERVER,
      port: process.env.WDIO_PORT,
      path: '/exist/apps/tei-publisher/test/portrait.jpg'
    };
    if (process.env.WDIO_PROTOCOL === 'https') {
        requestOptions.rejectUnauthorized = false;
    }

    function getImage (cb) {
      return new Promise(function(resolve, reject) {
        client.get(requestOptions, function(response) {
          var data = new Buffer([]);
          response.on('data', function addChunk(chunk) {
             data = Buffer.concat([data, chunk]);
          });
          response.on('end', function end() {
            try {
              resolve(data);
            }
            catch (e) {
              reject(e)
            }
          });
        });
      });
    }

    before(function () {
      image = browser.call(getImage);
    });

    it("should exist", function() {
        assert.equal(typeof image, 'object');
    });

    it("should have width", function() {
        assert.equal(sizeOf(image).width, 300)
    });
});
