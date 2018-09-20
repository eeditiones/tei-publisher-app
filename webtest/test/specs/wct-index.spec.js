var testIndex = "/exist/apps/tei-publisher/components/test/index.html";
var XMLWriter = require('xml-writer');

describe( 'wct test index', function() {
    let capabilities, session, specID;
    let timestamp, time, passes, failures, result;
    let suites, suite, suiteName, suiteDescription, suiteDuration;

    before( function() {
        browser.url( testIndex );
        browser.waitForExist( ".suite .suite .test" );
        capabilities = browser.desiredCapabilities['browserName'];
        time = browser.getText( "#mocha-stats li.duration em" );
        passes = parseInt( browser.getText( "#mocha-stats li.passes em" ), 10 );
        failures = parseInt( browser.getText( "#mocha-stats li.failures em" ), 10 );
        result = new XMLWriter( true );
        result.startDocument( '1.0', 'UTF-8' );
        result.startElement('testsuites');
    });

    after( function() {
        result.endElement();
        result.endDocument();
        console.log( result.toString() );
    });

    it( "get test results from web page", function() {
        browser.waitForExist( 'ul#mocha-report span.duration' );
        suites = browser.getTagName( 'ul#mocha-report *:first-child' );
        console.log( 'suites: ' + suites );
        suite = $( 'ul#mocha-report > li.suite > h1 > a' ).getText();
        suiteName = $( 'ul#mocha-report > li.suite > ul > li.suite > h1 > a' ).getText();
        suiteDescription = $( 'ul#mocha-report > li.suite > ul > li.suite > ul > li.test.pass.medium > h2' ).getText();
        suiteDuration = parseInt( $( 'ul#mocha-report > li.suite > ul > li.suite > ul > li.test.pass.medium > h2 > span.duration' ).getText(), 10) / 1000;
        result.startElement('testsuite');
        result.writeAttribute( 'name', 'overall' );
        timestamp = new Date().toISOString();
        result.writeAttribute( 'timestamp', timestamp ).writeAttribute( 'time', time );
        result.writeAttribute( 'tests', passes + failures ).writeAttribute( 'failures', failures );
        result.writeAttribute( 'errors', '0' ).writeAttribute( 'skipped', '0' );
        result.startElement( 'properties' );
        result.startElement( 'property' ).writeAttribute( 'name', 'suiteName').writeAttribute( 'value', suite ).endElement();
        result.startElement( 'property' ).writeAttribute( 'name', 'capabilities').writeAttribute( 'value', capabilities ).endElement();
        result.endElement();
        result.startElement( 'testcase' );
        result.writeAttribute( 'classname', capabilities + '.' + suite ).writeAttribute( 'name', suiteName ).writeAttribute( 'time', suiteDuration );
        result.endElement( 'testcase' );
        result.endElement();
    });

    it( "get the wb components failures", function() {
        assert.equal( 0, failures, "at least one failure" );
    });
});
