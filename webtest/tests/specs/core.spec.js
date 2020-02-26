const Page  = require('../pageobjects/Page');

let client = require(process.env.WDIO_PROTOCOL);
let sizeOf = require('image-size');
let path = require('path');

describe('browsing text', () => {

    it('open document', () => {
        Page.openUrl("/exist/apps/tei-publisher/index.html");

        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
        Page.waitForVisible(".tp-document-title-wrapper h5");
        assert.equal(Page.getElementText(".tp-document-title-wrapper h5"), "Critik der reinen Vernunft");
    });

    it("table of contents", () => {
        browser.click(".toc-toggle")
            .waitForVisible("#toc a[data-div='3.4.4.8']");

        browser.click("#toc li:nth-child(3) a[data-toggle='collapse'] span")
            .waitForVisible("a[data-div='3.4.4.8.7']");
        browser.click("a[data-div='3.4.4.8.7']");
        browser.waitForText(".content h1");
        assert.equal(Page.getElementText(".content h1"), 'Einleitung.');
    });

    it("next page", () => {
        browser.click(".nav-next").pause(200);
        browser.waitForText(".content .tei-corr1");
        assert.equal(Page.getElementText(".content .tei-corr1"), "Erkentniſſe");
    });

    it("previous page", () => {
        browser.click(".nav-prev").pause(200);

        browser.waitForText(".content h1");
        assert.equal(Page.getElementText(".content h1"), 'Einleitung.');
    });

    it("reload", () => {
        browser.refresh();

        assert.equal(Page.getElementText(".content h1"), 'Einleitung.');
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
        browser.click("#searchPageForm .glyphicon-search");

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
});

describe('view image on page', () => {
    let image;
    let requestOptions = {
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
          let data = new Buffer([]);
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

    it("should exist", () => {
        assert.equal(typeof image, 'object');
    });

    it("should have width", () => {
        assert.equal(sizeOf(image).width, 300)
    });
});
