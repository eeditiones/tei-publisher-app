browser.addCommand("login", function() {
    browser.waitForVisible("a[href='#loginDialog']");
    var loggedIn = browser.isExisting("a[href='?logout=true']");
    if (!loggedIn) {
        browser.click("a[href='#loginDialog']");
        browser.waitForVisible("#loginDialog");
        browser.setValue("input[name='user']", "tei");
        browser.setValue("input[name='password']", "simple");
        browser.submitForm("#loginDialog form");

        browser.waitForVisible("*=Admin");
    }
});
