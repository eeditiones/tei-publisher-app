const util = require('./util.js');
const path = require('path');
const FormData = require('form-data');
const chai = require('chai');
const chaiXML = require('chai-xml');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const jsdom = require("jsdom");
const zip = require('adm-zip');
const { readFileSync } = require('fs');
const { JSDOM } = jsdom;

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));
chai.use(chaiXML);

const testXml = `<TEI xmlns="http://www.tei-c.org/ns/1.0">
<teiHeader>
  <fileDesc>
    <titleStmt>
      <title>EPUB Cover Image Test</title>
    </titleStmt>
    <publicationStmt>
      <p />
    </publicationStmt>
    <sourceDesc>
      <p />
    </sourceDesc>
  </fileDesc>
</teiHeader>
<text>
  <body>
  <div type="document" n="1" xml:id="d1" subtype="document">
    <head>Document 1</head>
  </div>
  </body>
</text>
</TEI>`;

async function getEntries(data) {
  return new zip(Buffer.from(data)).getEntries().filter(({ entryName }) => ['OEBPS/content.opf', 'OEBPS/book.jpg'].includes(entryName));
}

describe('/api/document/{document}/epub?cover-image', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "cover.xml");
      formData.append('files[]', readFileSync('test/book.jpg'), "book.jpg");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(2);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/cover.xml');
      expect(res.data[1].name).to.equal('/db/apps/tei-publisher/data/playground/book.jpg');
      expect(res).to.satisfyApiSpec;
    });

    it('creating an epub without a cover image', async () => {
      const res = await util.axios.get('document/playground%2Fcover.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const enteries = await getEntries(res.data);
      expect(enteries.length).to.equal(1);
    });

    it('defining a cover image for the epub', async () => {
      const res = await util.axios.get('document/playground%2Fcover.xml/epub?cover-image=book.jpg', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const enteries = await getEntries(res.data);
      expect(enteries.length).to.equal(2);
      const content = new JSDOM(enteries[0].getData().toString(), { contentType: "application/xml" }).window.document;
      expect(content.querySelector('metadata meta[name="cover"]')).to.exist;
      expect(content.querySelector('manifest item[id="book.jpg"]').getAttribute('properties')).to.equal('cover-image');
    });

    after(util.logout);
});