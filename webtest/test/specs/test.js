var assert = require('assert');

describe('browsing text', function() {

    it('open document', function() {
        browser.url('http://localhost:8080/exist/apps/tei-publisher/index.html');
        
        browser.click("a[href*='kant_rvernunft_1781.TEI-P5.xml']")
        browser.waitForVisible(".col-title h5");
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
    });
    
    it("start page", function() {
        browser.click("#about a");
        assert(browser.isExisting("a[href*='kant_rvernunft_1781.TEI-P5.xml']"));
    });
});

// describe('navigate pages', function() {
//     it('open document', function() {
//         browser.url('http://localhost:8080/exist/apps/tei-publisher/index.html');
//         
//         browser.click("#documents-panel a[href*='documentation.xml']")
//         browser.waitForExist(".content div");
//         
//         while (browser.isVisible(".hidden-xs .nav-next")) {
//             browser.click(".hidden-xs .nav-next");
//             browser.pause(800);
//             browser.waitForExist(".content p");
//         }
//     });
// });

// describe('downloads', function() {
//     it('single page view', function() {
//         browser.click("#documents-panel a[href*='documentation.xml']")
//         browser.waitForVisible(".col-title h5");
//         var tab = browser.getCurrentTabId();
//         browser.click(".service-icon-bar a[data-template-mode='plain']");
//         console.log(browser.getUrl());
//         browser.switchTab();
//     });
// });

describe('admin functions', function() {
    it('login', function() {
        browser.url('http://localhost:8080/exist/apps/tei-publisher/index.html');
        
        browser.waitForVisible("a[href='#loginDialog']");
        browser.click("a[href='#loginDialog']");
        browser.waitForVisible("#loginDialog");
        browser.setValue("input[name='user']", "tei");
        browser.setValue("input[name='password']", "simple");
        browser.submitForm("#loginDialog form");
    });
    it("recompile odd", function() {
        assert(browser.isExisting("a.recompile"));
        browser.click("a[href*='source=dta.odd']");
        
        browser.waitForExist("#messageDialog .errors");
        var errors = browser.elements("#messageDialog .errors .list-group-item-danger");
        assert(errors.value.length == 0);
        var success = browser.elements("#messageDialog .errors .list-group-item-success");
        assert(success.value.length > 0);
        
        browser.click("#messageDialog button[type='submit']");
        browser.pause(300);
    });
    it("regenerate metadata index", function() {
        browser.click("*=Admin");
        browser.waitForVisible("#reindex");
        browser.click("#reindex");
        
        browser.waitForExist("#messageDialog .message");
    });
});