const chaiResponseValidator = require('chai-openapi-response-validator');
const util = require('./util.js');
const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const FormData = require('form-data');
const jsdom = require("jsdom");
const { JSDOM } = jsdom;

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

const testXml = `
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>Nested Footnotes Test</title>
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
            <p>Lorem aliquip proident et amet<note>Ea cupidatat dolor cupidatat officia aliqua exercitation in 
            cillum sint esse aute et nulla aute. Culpa eiusmod cupidatat id excepteur officia aliqua velit irure 
            consequat tempor. Nisi ad reprehenderit in cupidatat labore magna in nisi velit. Enim sit fugiat 
            do ex veniam enim amet sint quis<note>Veniam eu occaecat laborum eu enim.</note>.</note>.</p>
        </body>
    </text>
</TEI>
`;

describe('/api/document/{id}/html', function () {
    before(util.login);

    it('uploads a test document to playground collection', async function () {
        const formData = new FormData();
        formData.append('files[]', testXml, "footnotes.xml");
        const res = await util.axios.post('upload/playground', formData, {
            headers: formData.getHeaders()
        });
        expect(res.data).to.have.length(1);
        expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/footnotes.xml');
        expect(res).to.satisfyApiSpec;
    });

    it('checks for correct footnotes using /api/part', async function() {
        const res = await util.axios.get('parts/playground%2Ffootnotes.xml/json', {
            params: {
                view: 'single',
                xpath: '//body'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data.footnotes).to.exist;
        expect(res.data.content).to.exist;

        const fnFragment = JSDOM.fragment(res.data.footnotes);
        const footnotes = fnFragment.querySelectorAll('div > dl.footnote');
        expect(footnotes.length).to.equal(2);
        // first footnote should have a link to second footnote
        expect(footnotes[0].querySelector('a.note')).to.exist;
        // no footnotes inside footnotes
        expect(fnFragment.querySelector('dl.footnote dl.footnote')).to.be.null;

        const fragment = JSDOM.fragment(res.data.content);
        // expect two pb-popover corresponding to footnotes
        expect(fragment.querySelectorAll('pb-popover.footnote').length).to.equal(2);
        // but no footnote nested inside pb-popover
        expect(fragment.querySelector('pb-popover dl.footnote')).to.be.null;
        expect(res).to.satisfyApiSpec;
    });

    it('checks for correct footnotes using /api/document', async function () {
        const res = await util.axios.get('document/playground%2Ffootnotes.xml/html');

        expect(res.status).to.equal(200);

        const fragment = JSDOM.fragment(res.data);
        const footnotes = fragment.querySelectorAll('.footnotes > dl.footnote');
        expect(footnotes.length).to.equal(2);
        // first footnote should have a link to second footnote
        expect(footnotes[0].querySelector('a.note')).to.exist;
        // no footnotes inside footnotes
        expect(fragment.querySelector('dl.footnote dl.footnote')).to.be.null;
    });

    it('deletes the uploaded document', async function () {
        const res = await util.axios.delete('document/playground%2Ffootnotes.xml');
        expect(res.status).to.equal(204);
    });

    after(util.logout);
});