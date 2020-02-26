const Page  = require('../pageobjects/Page');
let path = require('path');

describe('edit odd', () => {
    before(function() {
        return browser.upload(
            path.join('test', 'graves7.xml'),
            "/exist/rest/db/apps/tei-publisher/data/test/graves7.xml"
        )
    });

    it('should open index page', () => {
        Page.openUrl("/exist/apps/tei-publisher/index.html");
        browser.login();
    });

    it("should create odd", () => {
        browser.setValue("#odds input[name='new_odd']", "testodd");
        browser.setValue("#odds input[name='title']", "Test ODD");
        browser.click("#odds button[type='submit']");
    });

    it("should open editor", () => {
        Page.openUrl("/exist/apps/tei-publisher/odd-editor.html?odd=testodd.odd");
        browser.waitForExist("#new-element input[ref='identNew']");
    });

    it("should create new element spec for names", () => {
        browser.setValue("#new-element input[ref='identNew']", "name");
        browser.click("#new-element button");

        browser.waitForExist("element-spec[ident='name']");
    });

    it("should edit new element spec", () => {
        let spec = $("element-spec[ident='name']");
        // spec.click("a[data-toggle='collapse']");
        // spec.waitForVisible("header h4 a[data-toggle='collapse']");
        spec.click("header h4 a[data-toggle='collapse']");
        spec.waitForVisible(".renditions");

        assert.equal(spec.$$('model').length, 1);

        spec.click(".renditions button");
        spec.waitForVisible(".renditions .CodeMirror-line");

        spec.click(".renditions .CodeMirror-line");
        spec.keys("font-variant: small-caps;");
    });

    it("should add model with alternate", () => {
        let spec = browser.element("element-spec[ident='name']");

        spec.click("h3 button.dropdown-toggle");
        spec.waitForVisible("h3 .dropdown-menu");
        spec.click("h3 .dropdown-menu li:nth-child(1)");
        browser.waitUntil(function() {
            return spec.elements("model").value.length == 2;
        });

        let model = spec.element("model:nth-child(1)");
        model.setValue("combobox[ref='behaviour'] input", "alternate");
        model.click(".predicate .CodeMirror-line");
        model.keys("type='person'");

        model.click(".parameters button");
        browser.waitUntil(function() {
            return model.elements("parameter").value.length == 1;
        });

        let param = model.elements("parameter").value[0];
        param.setValue("input", "default");
        param.click("code-editor");
        param.keys(".");

        model.click(".parameters button");
        browser.waitUntil(function() {
            return model.elements("parameter").value.length == 2;
        });

        param = model.elements("parameter").value[1];
        param.setValue("input", "alternate");
        param.click("code-editor");
        param.keys("id(substring-after(@key, '#'), root(.))");
    });

    it("should create new element spec for pb", () => {
        browser.setValue("#new-element input[ref='identNew']", "pb");
        browser.click("#new-element button");

        browser.waitForExist("element-spec[ident='pb']");
    });

    it("should open element spec for pb", () => {
        let spec = browser.element("element-spec[ident='pb']");
        // spec.click("a[data-toggle='collapse']");
        // spec.waitForVisible(".models");

        let model = spec.$('model');
        model.click("header h4 a[data-toggle='collapse']");
        model.waitForVisible(".parameters");

        model.setValue("combobox[ref='behaviour'] input", "omit");
    });

    it("should save odd", () => {
        browser.click("#save");
        Page.waitForVisible("#main-modal .message");
        assert.equal(browser.elements("#main-modal .message .list-group-item-success").value.length, 4);
    });
});

describe('check display', () => {
    it("should display letter", () => {
        Page.openUrl("/exist/apps/tei-publisher/test/graves7.xml?odd=testodd.odd");

        browser.waitForExist(".content");
    });

    it("test if place name is small caps", () => {
        let name = browser.element(".content .tei-name2");
        assert.equal(name.getCssProperty("font-variant").value, 'small-caps');
    });

    it("test if person name has alternate", () => {
        let person = browser.element(".content .alternate");
        assert(person);
    });

    it("test if pb is shown", () => {
        let pb = $$(".content .tei-pb");
        assert.equal(pb.length, 0);
    });
});

describe('modify odd', () => {
    it("should open editor", () => {
        Page.openUrl("/exist/apps/tei-publisher/odd-editor.html?odd=testodd.odd");
        browser.waitForExist("element-spec[ident='pb']");
    });

    it("should remove pb element spec", () => {
        let spec = $("element-spec[ident='pb']");
        spec.click("button=delete");

        Page.waitForVisible("#main-modal button[ref='confirm']");
        browser.click("#main-modal button[ref='confirm']");

        browser.pause(400);
    });

    it("should save odd", () => {
        browser.click("#save");
        Page.waitForVisible("#main-modal .message");
        assert.equal(browser.elements("#main-modal .message .list-group-item-success").value.length, 4);
    });
});

describe('recheck display', () => {
    it("should display letter", () => {
        Page.openUrl("/exist/apps/tei-publisher/test/graves7.xml?odd=testodd.odd");

        browser.waitForExist(".content");
    });

    it("test if pb is shown", () => {
        let pb = $$(".content .tei-pb");
        assert(pb.length > 0);
    });

    after(function() {
        Page.openUrl("/exist/apps/tei-publisher/index.html?action=delete-odd&docs[]=testodd.odd");
        Page.openUrl("/exist/apps/tei-publisher/index.html?action=delete&docs[]=test/graves7.xml");
    });
});
