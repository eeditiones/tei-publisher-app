const Page  = require('../pageobjects/Page');

let client = require(process.env.WDIO_PROTOCOL);

// adds global PDFJS to scope
require('pdfjs-dist');

let pdfPath = '/exist/apps/tei-publisher/doc/documentation.xml.pdf?odd=docbook.odd&cache=no';
let requestOptions = {
  hostname: process.env.WDIO_SERVER,
  port: process.env.WDIO_PORT,
  path: pdfPath
};
if (process.env.WDIO_PROTOCOL === 'https') {
    requestOptions.rejectUnauthorized = false;
}

describe('PDF', () => {
  // let documentPromise = null;
  let document;

  function getPDF (cb) {
    return new Promise(function(resolve, reject) {
      client.get(requestOptions, function(response) {
        let data = new Buffer([]);
        response.on('data', function addChunk(chunk) {
           data = Buffer.concat([data, chunk]);
        });
        response.on('end', function end() {
          try {
            let pdfPromise = PDFJS.getDocument(data);
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
    assert.equal(document.numPages, 23);
  });
});
