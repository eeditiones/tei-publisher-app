var client = require(process.env.WDIO_PROTOCOL);

// adds global PDFJS to scope
require('pdfjs-dist');

var pdfPath = '/exist/apps/tei-publisher/doc/documentation.xml.pdf';
var requestOptions = {
  hostname: process.env.WDIO_SERVER,
  port: process.env.WDIO_PORT,
  path: pdfPath
};
if (process.env.WDIO_PROTOCOL === 'https') {
    requestOptions.rejectUnauthorized = false;
}

describe('PDF', function() {
  // var documentPromise = null;
  var document;

  function getPDF (cb) {
    return new Promise(function(resolve, reject) {
      client.get(requestOptions, function(response) {
        var data = new Buffer([]);
        response.on('data', function addChunk(chunk) {
           data = Buffer.concat([data, chunk]);
        });
        response.on('end', function end() {
          try {
            var pdfPromise = PDFJS.getDocument(data);
            resolve(pdfPromise);
          }
          catch (e) {
            reject(e)
          }
        });
      });
    });
  }

  before(function () {
    document = browser.call(getPDF)
  })

  it('should exist', function () {
    assert.equal(typeof document, 'object');
  });

  it('should have a certain number of pages', function (done) {
    assert.equal(document.numPages, 17);
  });
});
