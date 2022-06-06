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
      <title>EPUB note popup styles</title>
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
      <note n="1" xml:id="d1fn1" type="source"><hi rend="italic">italic note</hi></note>
      <note n="2" xml:id="d1fn2" type="source"><hi rend="bold">bold note</hi></note>
      <note n="3" xml:id="d1fn3" type="source"><hi rend="underline">underlined note</hi></note>
    </div>
    <div type="document" n="2" xml:id="d2" subtype="document">
      <head>Document 2</head>
      <p><hi rend="italic">italic note</hi></p>
      <p><hi rend="bold">bold note</hi></p>
      <p><hi rend="underline">underlined note</hi></p>
    </div>
  </body>
</text>
</TEI>`;

function getPages(data) {
  return new zip(Buffer.from(data)).getEntries()
    .filter(({ entryName }) => entryName.startsWith('OEBPS/N'))
    .map(entry => entry?.getData().toString('utf-8'));
}

describe('Text style in footnotes popup', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "note-popup.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/note-popup.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('em, strong, and u elements should be used to style texts in notes', async () => {
      const res = await util.axios.get('document/playground%2Fnote-popup.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const pages = getPages(res.data);
      const document1 = new JSDOM(pages[0], { contentType: "application/xml" }).window.document;
      expect(document1.querySelector('aside em').textContent.trim()).to.equal('italic note');
      expect(document1.querySelector('aside strong').textContent.trim()).to.equal('bold note');
      expect(document1.querySelector('aside u').textContent.trim()).to.equal('underlined note');
      const document2 = new JSDOM(pages[1], { contentType: "application/xml" }).window.document;
      expect(document2.querySelector('p em')).to.be.null;
      expect(document2.querySelector('p strong')).to.be.null;
      expect(document2.querySelector('p u')).to.be.null;
    });

    after(util.logout);
});