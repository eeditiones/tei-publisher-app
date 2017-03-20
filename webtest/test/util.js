var path = require('path');
var fs = require('fs');
var request = require('request');

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

browser.addCommand("upload", function(source, target, done) {
    var url = process.env.WDIO_PROTOCOL + "://" + process.env.WDIO_SERVER + ":" + 
        process.env.WDIO_PORT + target;
    var options = {
        url: url,
        method: "PUT",
        strictSSL: false,
        auth: {
            user: "tei",
            pass: "simple",
            sendImmediately: true
        }
    };
    return new Promise(function(resolve, reject) {
        fs.createReadStream(source).pipe(
            request(
                options,
                function (error, response, body) {
                    if (error) {
                      return console.error('Upload failed:', error);
                      reject();
                    }
                    resolve('File uploaded:' + source);
                }
            )
        );
    });
});

browser.addCommand("uninstall", function(pkg) {
    var query = 'repo:undeploy("' + pkg + '"), repo:remove("' + pkg + '")';
    var url = process.env.WDIO_PROTOCOL + "://" + process.env.WDIO_SERVER + ":" + 
        process.env.WDIO_PORT + "/exist/rest/db?_query=" + query;
    var options = {
        url: url,
        method: "GET",
        strictSSL: false,
        auth: {
            user: "admin",
            pass: "",
            sendImmediately: true
        }
    };
    return new Promise(function(resolve, reject) {
        request(options, function (error, response, body) {
            if (error) {
                reject("Removing package " + pkg + "failed");
            }
            resolve("Package removed: " + pkg);
        });
    });
});