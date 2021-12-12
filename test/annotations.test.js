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
            <p><ref target="#">Starb am<note place="footnote">Fehlt.</note></ref>. Sammlung: Opuscula theologica.</p>
            <p><hi>Zum <choice><abbr>Bsp.</abbr><expan>Beispiel</expan></choice></hi> Opuscula theologica.</p>
            <p>Lorem ipsum dolor sit amet.</p>
            <p>Lorem <choice><abbr>ipsum dolor</abbr><expan>sit amet</expan></choice> sit amet.</p>
            <p>Bei <persName type="author" ref="kbga-actors-8470">Budé</persName> (Anm. 21), S. 56f.59, finden sich zwei Briefe von Fontenelle an Turettini, in denen <persName ref="kbga-actors-8482">Fontenelle</persName> sich lobend über <persName ref="kbga-actors-1319">Werenfels</persName> äußert. Den erwähnten Dank formulierte <persName ref="kbga-actors-1319">Werenfels</persName> in Form eines Epigramms; vgl. <persName type="author" ref="kbga-actors-1319">S. Werenfels</persName>, <hi rend="i">Fasciculus Epigrammatum</hi>, in: ders., <hi rend="i">Opuscula</hi> III (Anm. 20), S. 337–428, dort S. 384:</p>
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
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0"><ref target="#">Starb am<note place="footnote">Fehlt.</note></ref>. Sammlung: <hi>Opuscula theologica</hi>.</p>');
    });

    it('wrap to end of paragraph', async function() {
      const document = await annotate([
        {
          "context": "1.4.2.16",
          "start": 210,
          "end": 308,
          "text": "S. Werenfels, Fasciculus Epigrammatum, in: ders., Opuscula III (Anm. 20), S. 337–428, dort S. 384:",
          "type": "link",
          "properties": {
            "target": "#foo"
          }
        }
      ]);
      const para = document.querySelector("body p:nth-child(8)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">Bei <persName type="author" ref="kbga-actors-8470">Budé</persName> (Anm. 21), S. 56f.59, finden sich zwei Briefe von Fontenelle an Turettini, in denen <persName ref="kbga-actors-8482">Fontenelle</persName> sich lobend über <persName ref="kbga-actors-1319">Werenfels</persName> äußert. Den erwähnten Dank formulierte <persName ref="kbga-actors-1319">Werenfels</persName> in Form eines Epigramms; vgl. <ref target="#foo"><persName type="author" ref="kbga-actors-1319">S. Werenfels</persName>, <hi rend="i">Fasciculus Epigrammatum</hi>, in: ders., <hi rend="i">Opuscula</hi> III (Anm. 20), S. 337–428, dort S. 384:</ref></p>');
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

    it('insert choice/abbr/expan', async function() {
      const document = await annotate([
        {
          "context": "1.4.2.12",
          "start": 6,
          "end": 17,
          "text": "ipsum dolor",
          "type": "abbreviation",
          "properties": {
            "expan": "sit amet"
          }
        }
      ]);
      const para = document.querySelector("body p:nth-child(6)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">Lorem <choice><abbr>ipsum dolor</abbr><expan>sit amet</expan></choice> sit amet.</p>');
    });

    it('insert app/lem/rdg', async function() {
      const document = await annotate([
        {
          "context": "1.4.2.12",
          "start": 6,
          "end": 17,
          "text": "ipsum dolor",
          "type": "app",
          "properties": {
            "wit[1]": "#me",
            "rdg[1]": "sit amet"
          }
        }
      ]);
      const para = document.querySelector("body p:nth-child(6)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">Lorem <app><lem>ipsum dolor</lem><rdg wit="#me">sit amet</rdg></app> sit amet.</p>');
    });

    it('delete choice/abbr/expan', async function() {
      const document = await annotate([
        {
          "type": "delete",
          "node": "1.4.2.14.2",
          "context": "1.4.2.14"
        }
      ]);
      const para = document.querySelector("body p:nth-child(7)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">Lorem ipsum dolor sit amet.</p>');
    });

    it('delete element containing note', async function() {
      const document = await annotate([
        {
          "type": "delete",
          "node": "1.4.2.8.1",
          "context": "1.4.2.8"
        }
      ]);
      const para = document.querySelector("body p:nth-child(4)");
      expect(para.outerHTML).xml.to.equal('<p xmlns="http://www.tei-c.org/ns/1.0">Starb am<note place="footnote">Fehlt.</note>. Sammlung: Opuscula theologica.</p>');
    });

    after(util.logout);
});