const util = require('./util.js');
const path = require('path');
const FormData = require('form-data');
const fs = require('fs');
const tmp = require('tmp');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

describe('/api/collection', function () {
    this.timeout(30000);

    it('retrieves document list for default data collection', async function () {
        const res = await util.axios.get('collection');

        expect(res.status).to.equal(200);
        expect(res.data).to.be.a('string').that.includes('TEI Publisher Demo Collection');
        expect(res.data).to.be.a('string').that.includes('Playground');
        expect(res).to.satisfyApiSpec;
    });

    it('retrieves document list for test collection', async function () {
        const res = await util.axios.get('collection/test');

        expect(res.status).to.equal(200);
        expect(res.data).to.be.a('string').that.includes('Up');
        expect(res.data).to.be.a('string').that.includes('Bogactwa mowy polskiej');
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/upload', function() {
    before(util.login);

    it('uploads a document to playground collection', async function () {
        const formData = new FormData()
        formData.append('files[]', fs.createReadStream(path.join(__dirname, '../data/test/graves6.xml')), 'graves6.xml')
        const res = await util.axios.post('upload/playground', formData, {
            headers: formData.getHeaders()
        });
        expect(res.data).to.have.length(1);
        expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/playground/graves6.xml');
        expect(res).to.satisfyApiSpec;
    });

    it('deletes the uploaded document', async function () {
        const res = await util.axios.delete('document/playground%2Fgraves6.xml')
        expect(res.status).to.equal(204);
    });

    it('uploads a document to the root collection of the app', async function () {
        const formData = new FormData()
        formData.append('files[]', fs.createReadStream(path.join(__dirname, '../data/test/let695.xml')), 'let695.xml')
        const res = await util.axios.post('upload', formData, {
            headers: formData.getHeaders()
        });
        expect(res.data).to.have.length(1);
        expect(res.data[0].name).to.equal('/db/apps/tei-publisher/data/let695.xml');
        expect(res).to.satisfyApiSpec;
    });

    it('deletes the uploaded document from root collection', async function () {
        const res = await util.axios.delete('document/let695.xml')
        expect(res.status).to.equal(204);
    });

    after(util.logout);
});

describe('/api/upload [unauthorized]', function () {
    it('tries to upload a document to playground collection', function (done) {
        const formData = new FormData()
        formData.append('files[]', fs.createReadStream(path.join(__dirname, '../data/test/graves6.xml')), 'graves6.xml')
        util.axios.post('upload/playground', formData, {
            headers: formData.getHeaders()
        })
        .catch(function(error) {
            expect(error.response.status).to.equal(401);
            expect(error.response).to.satisfyApiSpec;
            done();
        });
    });
});