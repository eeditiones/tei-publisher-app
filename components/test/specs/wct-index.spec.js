var testIndex = '/exist/apps/tei-publisher/components/test/index.html';
/* XMLwriter: https://github.com/Inist-CNRS/node-xml-writer/#api-documentation */
var XMLWriter = require('xml-writer');
var fs = require('fs');

describe('wct test index', function () {
  /* add global viariables */
  let result, suite,
      capabilities, totalTime, totalPasses, totalFailures;

  before(function () {
    browser.url(testIndex);
    /* start not before the rusult page is loaded */
    browser.waitForExist('.suite .suite .test');

    capabilities = browser.desiredCapabilities['browserName'];
    totalTime = browser.getText('#mocha-stats li.duration em');
    totalPasses = parseInt(browser.getText('#mocha-stats li.passes em'), 10);
    totalFailures = parseInt(browser.getText('#mocha-stats li.failures em'), 10);

    /* start XML report */
    result = new XMLWriter(true);
    result.startDocument('1.0', 'UTF-8');
    result.startElement('testsuites');
  });

  function xmlReportSuite (suite) {
    /* get all test suites */
    let nestedSuites = suite.$$('.suite')
        .map(function (testSuite) {
          /* set starting time */
          let timestamp = new Date().toISOString();

          /* read test suites from index file */
          let testSourceFile = suite.$('h1:first-child > a').getText();
          let testSuiteName = testSuite.$('h1:first-child > a').getText();
          /* test suite head */
          startTestSuiteXML(testSuiteName, timestamp, totalTime);
          testPropertiesXML(testSourceFile);

          /* each test case inside a test suite */
          let testClassName, testCaseName, testCaseTime;
          let testCases = suite.$$('.test')
              .map(function (testCase) {
                testClassName = capabilities + '.' + testSuiteName;
                /* read H2 test without containing sub notes */
                testCaseName = testCase.$('h2').getHTML(false).match(/[^<]+/)[0];
              });
          let testPasses = suite.$$('.test.pass')
              .map(function (testCase) {
                /* test time as integer */
                testCaseTime = parseInt(testCase.$('h2 .duration').getText(), 10) / 1000;
                startTestCaseXML(testCase, testClassName, testCaseName, testCaseTime);
                endTestCaseXML();
              });
          let testFails = suite.$$('.test.fail')
              .map(function (testCase) {
                /* false test does not contain a duration time */
                startTestCaseXML(testCase, testClassName, testCaseName);
                xmlFailReportSuite(testCase);
                endTestCaseXML();
              });
          endTestSuiteXML();
        });
  }

  function startTestSuiteXML (testSuiteName, timestamp, totalTime) {
    result.startElement('testsuite');
    result.writeAttribute('name', testSuiteName );
    result.writeAttribute('timestamp', timestamp)
      .writeAttribute('time', totalTime);
    result.writeAttribute('tests', totalPasses + totalFailures)
      .writeAttribute('failures', totalFailures);
    /* fake errors and skipped test numbers */
    result.writeAttribute('errors', '0')
      .writeAttribute('skipped', '0');
  }
  function endTestSuiteXML () {
    result.endElement ();
  }

  function testPropertiesXML (testSourceFile) {
    result.startElement('properties');
    result.startElement('property')
      .writeAttribute('testfile', testSourceFile).endElement();
    result.startElement('property')
      .writeAttribute('name', 'capabilities')
      .writeAttribute('value', capabilities).endElement();
    result.endElement();
  }

  function startTestCaseXML (testCase,
                             testClassName,
                             testCaseName,
                             testCaseTime) {
    function caseTime (testCaseTime) {
      if (testCaseTime) {
        result.writeAttribute('time', testCaseTime);
      } else {
        result.writeAttribute('time', totalTime);
      }
    };
    result.startElement('testcase')
      .writeAttribute('classname', testClassName)
      .writeAttribute('name', testCaseName);
    caseTime(testCaseTime);
  }
  function endTestCaseXML () {
    result.endElement();
  }

  function xmlFailReportSuite (testCase) {
    result.startElement('error')
      .writeAttribute(
        'message',
        /* get shortened error message */
        testCase.$('pre.error').getText().split(' \'')[0])
      .endElement();
    /* full error message */
    result.startElement('system-err');
    result.writeCData(
      "\n" + testCase.$('pre.error').getText() + "\n");
    result.endElement();
  }

  describe('write results to console', function () {
    let xmlFileReport;
    before(function () {
      let xmlReport = $$('#mocha-report > .suite').map(xmlReportSuite);

      /* close XML report */
      result.endElement().endDocument();

      /* write report to disk */
      let xmlFile = 'reports\/junit-report-' + capabilities + '-' + Date.now() + '.xml';
      fs.writeFile(
        xmlFile,
        result.toString(),
        (err) => {
          if (err) throw err;
          xmlFileReport = xmlFile + ' has been written';
        });
      console.log(result.toString());
      browser.pause(300);
      console.log(xmlFileReport);
    });

    it('write report to JUnit XML', function () {
      assert.match(xmlFileReport, /^reports/);
    });

    it('at least one passed test', function () {
      assert.isAbove(totalPasses, 0);
    });

    it('no failed test cases', function () {
      assert.equal(totalFailures, 0);
    });
  });
});
