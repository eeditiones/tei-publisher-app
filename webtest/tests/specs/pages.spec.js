/**
 * Checks browsing through pages
 */

const Page  = require('../pageobjects/Page');
const headline = '#view #content h1';
const headlineText = 'Quickstart';
const documentUrl = 'doc/documentation.xml';
const documentWithParametersUrl = documentUrl + '?odd=documentation.odd&view=div&root=';

describe('browsing a text', () => {
    let next;
    it('should open a document', () => {
        Page.open(documentUrl);
        Page.waitUntil(() => {
          return $('h1').getText() === headlineText
        }, 5000, 'expected text to be different found 5s');
        let text = $('h1').getText();
        assert.equal(text, headlineText);
    });

    it.skip('should navigate forward', () => {
        while (Page.isElementExisting(".nav-next")) {
            next = Page.getElementAttribute(".nav-next", "data-root");
            Page.open(documentWithParametersUrl + next);
            Page.waitForVisible(headline);
            assert.equal(Page.getElementText(headline), "TEI Publisher");
        }
    });

    it.skip('should navigate backward', () => {
        while (Page.isElementExisting(".nav-prev")) {
            next = Page.getElementAttribute(".nav-prev", "data-root");
            Page.open(documentWithParametersUrl + next);
            Page.waitForVisible(headline);
            assert.equal(Page.getElementText(headline), "TEI Publisher");
        }
    });
});
