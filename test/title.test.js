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
      <title>EPUB Title Test</title>
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
      <head>Document</head>
    </div>
  </body>
</text>
</TEI>`;

function getPages(data) {
  return new zip(Buffer.from(data)).getEntries().filter(({ entryName }) => ['OEBPS/content.opf', 'OEBPS/toc.ncx', 'OEBPS/title.xhtml'].includes(entryName)).map(page => page.getData().toString('utf-8'));
}

describe('/api/document/{document}}/epub?skip-title=true', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "title.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/title.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('include title page', async () => {
      const res = await util.axios.get('document/playground%2Ftitle.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const pages = getPages(res.data);
      expect(pages.length).to.equal(3);
      const content = new JSDOM(pages[0], { contentType: "application/xml" }).window.document;
      expect(content.querySelector('manifest item#title')).to.exist;
      expect(content.querySelector('spine itemref[idref="title"]')).to.exist;
      const toc = new JSDOM(pages[2], { contentType: "application/xml" }).window.document;
      expect(toc.querySelector('navMap navPoint#navpoint-title')).to.exist;
    });

    it('exclude title page', async () => {
      const res = await util.axios.get('document/playground%2Ftitle.xml/epub?skip-title=true', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      const pages = getPages(res.data);
      expect(pages.length).to.equal(2);
      const content = new JSDOM(pages[0], { contentType: "application/xml" }).window.document;
      expect(content.querySelector('manifest item#title')).not.to.exist;
      expect(content.querySelector('spine itemref[idref="title"]')).not.to.exist;
      const toc = new JSDOM(pages[1], { contentType: "application/xml" }).window.document;
      expect(toc.querySelector('navMap navPoint#navpoint-title')).not.to.exist;
    });

    after(util.logout);
});