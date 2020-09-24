const jsdom = require("jsdom");
const { JSDOM } = jsdom;
const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');

const server = 'http://localhost:8080/exist/apps/tei-publisher';

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

describe('/{doc}', function () {
    it('Should retrieve matching view template', async function() {
        const res = await axios.get(`${server}/test%2Forlik_to_serafin.xml`);
        expect(res.status).to.equal(200);

        const parser = new JSDOM(res.data);
        const doc = parser.window.document;
        const meta = doc.querySelector('meta[name="description"]');
        expect(meta).to.exist;
        expect(meta.getAttribute('content')).to.equal('Serafin Letter');

        const pbDocument = doc.querySelector('pb-document');
        expect(pbDocument).to.exist;
        expect(pbDocument.getAttribute('path')).to.equal('test/orlik_to_serafin.xml');
        expect(pbDocument.getAttribute('odd')).to.equal('serafin');

        expect(res).to.satisfyApiSpec;
    });
});

describe('/{file}.html', function () {
    it('Should retrieve HTML file', async function () {
        const res = await axios.get(`${server}/index.html`);
        expect(res.status).to.equal(200);
        const parser = new JSDOM(res.data);
        const doc = parser.window.document;
        const pbBrowse = doc.querySelector('pb-browse-docs');
        expect(pbBrowse).to.exist;

        expect(res).to.satisfyApiSpec;
    });
});