const util = require('./util.js');
const path = require('path');
const FormData = require('form-data');
const chai = require('chai');
const chaiXML = require('chai-xml');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const jsdom = require("jsdom");
const zip = require('adm-zip');
const { JSDOM } = jsdom;

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));
chai.use(chaiXML);

const testXml = `<TEI xmlns="http://www.tei-c.org/ns/1.0">
<teiHeader>
  <fileDesc>
    <titleStmt>
      <title>EPUB title notes Test</title>
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
      <head>Document 1<note n="1" xml:id="d1fn1" type="source">note</note></head>
      <p>Document 1 body</p>
    </div>
  </body>
</text>
</TEI>`;

function getNav(data) {
  return new zip(Buffer.from(data)).getEntries().find(({ entryName }) => entryName === 'OEBPS/nav.xhtml')?.getData().toString('utf-8');
}

describe('Notes in document title', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "title-note.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/title-note.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('notes in document title should not appear in navigation entry', async () => {
      const res = await util.axios.get('document/playground%2Ftitle-note.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const document = new JSDOM(getNav(res.data), { contentType: "application/xml" }).window.document;
      expect(document.querySelector('a[href$="#d1"]').textContent).to.equal('Document 1');
    });

    after(util.logout);
});