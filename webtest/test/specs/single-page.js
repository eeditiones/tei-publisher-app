var client = require(process.env.WDIO_PROTOCOL);

var plainPath = '/exist/apps/tei-publisher/doc/kant_rvernunft_1781.TEI-P5.xml?cache=no&odd=documentation.odd&mode=plain';
var requestOptions = {
  hostname: process.env.WDIO_SERVER,
  port: process.env.WDIO_PORT,
  path: plainPath
};
if (process.env.WDIO_PROTOCOL === 'https') {
    requestOptions.rejectUnauthorized = false;
}

describe('Get plain HTML', function() {
  // var documentPromise = null;
  var document;

  function getPlain (cb) {
    return new Promise(function(resolve, reject) {
      client.get(requestOptions, function(response) {
        var data = new Buffer([]);
        response.on('data', function addChunk(chunk) {
           data = Buffer.concat([data, chunk]);
        });
        response.on('end', function end() {
          try {
              resolve(data.toString());
          } catch (e) {
              reject(e)
          }
        });
      });
    });
  }

  before(function () {
    document = browser.call(getPlain)
  })

  it('should exist', function () {
    assert.equal(typeof document, 'string');
  });

  it('should have length > 0', function (done) {
    assert(document.length > 0);
  });
});
