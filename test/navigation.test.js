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
      <title>EPUB Navigation Test</title>
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
  <front>
    <div type="document" n="1" xml:id="d1" subtype="pre-document">
      <head>Pre-Document 1</head>
      <p>Pre-Document 1 body</p>
    </div>
    <div type="document" n="2" xml:id="d2" subtype="pre-document">
      <head>Pre-Document 2</head>
      <p>Pre-Document 2 body</p>
    </div>
    <div type="document" n="3" xml:id="d3" subtype="pre-document">
      <head>Pre-Document 3</head>
      <p>Pre-Document 3 body</p>
    </div>
  </front>
  <body>
    <div type="document" n="4" xml:id="d4" subtype="document">
      <head>Document 4</head>
      <p>Document 4 body</p>
    </div>
    <div type="document" n="5" xml:id="d5" subtype="document">
      <head>Document 5</head>
      <p>Document 5 body</p>
    </div>
    <div type="document" n="6" xml:id="d6" subtype="document">
      <head>Document 6</head>
      <p>Document 6 body</p>
    </div>
  </body>
</text>
</TEI>`;

function getNav(data) {
  return new zip(Buffer.from(data)).getEntries().find(({ entryName }) => entryName === 'OEBPS/nav.xhtml')?.getData().toString('utf-8');
}

describe('/api/document/{document}}/epub?nav-root=', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "nav.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/nav.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('let tei-publisher determine the navigation root', async () => {
      const res = await util.axios.get('document/playground%2Fnav.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const document = new JSDOM(getNav(res.data), { contentType: "application/xml" }).window.document;
      expect(document.querySelectorAll('li').length).to.equal(3);
    });

    it('define navigation root', async () => {
      const res = await util.axios.get('document/playground%2Fnav.xml/epub?nav-root=1/4', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const document = new JSDOM(getNav(res.data), { contentType: "application/xml" }).window.document;
      expect(document.querySelectorAll('li').length).to.equal(6);
    });

    after(util.logout);
});