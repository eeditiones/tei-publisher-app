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
      <title>EPUB Images Collection Test</title>
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
    <graphic url="demo.png" />
  </div>
  </body>
</text>
</TEI>`;

function getImage(data) {
  return new zip(Buffer.from(data)).getEntries().find(({ entryName }) => entryName === 'OEBPS/demo.png');
}

describe('/api/document/{document}}/epub?images-colection', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "images.xml");
      const res = await util.axios.post('upload/playground', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/images.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('let tei-publisher determine images collection', async () => {
      const res = await util.axios.get('document/playground%2Fimages.xml/epub', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      expect(getImage(res.data)).to.be.undefined;
    });

    it('define images collection', async () => {
      const res = await util.axios.get('document/playground%2Fimages.xml/epub?images-collection=/db/apps/tei-publisher/data', { responseType: 'arraybuffer' });
      expect(res.status).to.equal(200);
      expect(getImage(res.data)).to.not.be.undefined;
    });

    after(util.logout);
});