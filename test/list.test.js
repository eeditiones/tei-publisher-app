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
      <title>EPUB Internal References</title>
    </titleStmt>
    <publicationStmt>
      <p/>
    </publicationStmt>
    <sourceDesc>
      <p/>
    </sourceDesc>
  </fileDesc>
</teiHeader>
<text>
  <body>
    <div type="document" n="1" xml:id="d1" subtype="document">
      <head>Document 1</head>
      <list>
          <head>head</head>
          <item>item 1</item>
          <item>item 2</item>
          <item>item 3</item>
      </list>
    </div>
  </body>
</text>
</TEI>`;

function getPage(data) {
  return new zip(Buffer.from(data)).getEntries()
    .find(({ entryName }) => entryName.startsWith('OEBPS/N'))
    .getData().toString('utf-8');
}

describe('Lists', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "list-head.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/list-head.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('Should render list head', async () => {
      const res = await util.axios.get('document/playground%2Flist-head.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const page = new JSDOM(getPage(res.data), { contentType: "application/xml" }).window.document;
      const items = page.querySelectorAll('ul > li');
      expect(items.length).to.equal(4);
      expect(items[0].className).to.equal('tei-head5');
    });

    after(util.logout);
});