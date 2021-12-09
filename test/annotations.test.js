const util = require('./util.js');
const path = require('path');
const FormData = require('form-data');
const chai = require('chai');
const chaiXML = require('chai-xml');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const jsdom = require("jsdom");
const { JSDOM } = jsdom;

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));
chai.use(chaiXML);

const testXml = `
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>Annotations Test</title>
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
            <p>(<persName type="author" ref="Gauger">Gauger</persName> I, 113).</p>
            <p>(113, <persName type="author" ref="Gauger">Gauger</persName> I).</p>
            <p>113, <persName type="author" ref="Gauger">Gauger</persName></p>
            <p><seg type="bio">Starb am<note place="footnote">Fehlt.</note></seg>. Sammlung: Opuscula theologica.</p>
            <p><hi>Zum <choice><abbr>Bsp.</abbr><expan>Beispiel</expan></choice></hi> Opuscula theologica.</p>
        </body>
    </text>
</TEI>
`;

async function annotate(json) {
    const res = await util.axios.post('annotations/merge/annotate%2Fannotations.xml', json);
    expect(res.status).to.equal(200);
    expect(res).to.satisfyApiSpec;
    expect(res.data.changes).to.have.length(1);
    
    const { document } = new JSDOM(res.data.content, {
        contentType: "application/xml"
    }).window;

    return document;
}

describe('/api/annotations/merge', function() {
    before(async () => {
      await util.login();
      const formData = new FormData()
      formData.append('files[]', testXml, "annotations.xml");
      const res = await util.axios.post('upload/annotate', formData, {
          headers: formData.getHeaders()
      });
      expect(res.data).to.have.length(1);
      expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/annotate/annotations.xml');
      expect(res).to.satisfyApiSpec;
    });

    it('deletes at start and wraps', async function() {
        const document = await annotate([
            {
              "type": "delete",
              "node": "1.4.2.2.2",
              "context": "1.4.2.2"
            },
            {
              "context": "1.4.2.2",
              "start": 1,
              "end": 9,
              "text": "Gauger I",
              "type": "hi",
              "properties": {}
            },
            {
              "context": "1.4.2.2",
              "start": 11,
              "end": 14,
              "text": "113",
              "type": "hi",
              "properties": {}
            },
            {
              "context": "1.4.2.2",
              "start": 1,
              "end": 13,
              "text": "Gauger I, 113",
              "type": "link",
              "properties": {
                "target": "#foo"
              }
            }
        ]);
        const para = document.querySelector("body p:nth-child(1)");
        expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">(<ref target="#foo"><hi>Gauger I</hi>, <hi>113</hi></ref>).</p>');
    });

    it('deletes at end and wraps', async function() {
        const document = await annotate([
            {
              "type": "delete",
              "node": "1.4.2.4.2",
              "context": "1.4.2.4"
            },
            {
              "context": "1.4.2.4",
              "start": 1,
              "end": 4,
              "text": "113",
              "type": "hi",
              "properties": {}
            },
            {
              "context": "1.4.2.4",
              "start": 6,
              "end": 14,
              "text": "Gauger I",
              "type": "hi",
              "properties": {}
            },
            {
              "context": "1.4.2.4",
              "start": 1,
              "end": 13,
              "text": "113, Gauger I",
              "type": "link",
              "properties": {
                "target": "#foo"
              }
            }
        ]);
        const para = document.querySelector("body p:nth-child(2)");
        expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">(<ref target="#foo"><hi>113</hi>, <hi>Gauger I</hi></ref>).</p>');
    });

    it('annotate after nested note', async function() {
      const document = await annotate([
        {
          "context": "1.4.2.8",
          "start": 20,
          "end": 39,
          "text": "Opuscula theologica",
          "type": "hi",
          "properties": {}
        }
      ]);
      const para = document.querySelector("body p:nth-child(4)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0"><seg type="bio">Starb am<note place="footnote">Fehlt.</note></seg>. Sammlung: <hi>Opuscula theologica</hi>.</p>');
    });

    it('annotate after nested choice', async function() {
      const document = await annotate([
        {
          "context": "1.4.2.10",
          "start": 9,
          "end": 28,
          "text": "Opuscula theologica",
          "type": "hi",
          "properties": {}
        }
      ]);
      const para = document.querySelector("body p:nth-child(5)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0"><hi>Zum <choice><abbr>Bsp.</abbr><expan>Beispiel</expan></choice></hi> <hi>Opuscula theologica</hi>.</p>');
    });

    after(util.logout);
});