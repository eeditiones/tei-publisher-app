const util = require('./util.js');
const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

describe('/api/odd/{odd} [authenticated]', function () {

    before(util.login);

    it('creates new odd', async function () {
        this.timeout(10000);
        this.slow(5000);
        const res = await util.axios.request({
            url: 'odd/testme',
            method: 'post',
            params: {
                "title": "My test"
            }
        });
        expect(res.status).to.equal(201);
        expect(res.data.path).to.equal('/db/apps/tei-publisher/odd/testme.odd');
        expect(res).to.satisfyApiSpec;
    });

    it('retrieves odd', async function() {
        const res = await util.axios.get('odd/testme.odd', {
            headers: {
                "Accept": "application/xml"
            }
        });
        expect(res.status).to.equal(200);
        expect(res.data).to.match(/schemaSpec/);
        expect(res).to.satisfyApiSpec;
    });

    it('loads odd as json', async function () {
        const res = await util.axios.get('odd/testme.odd', {
            headers: {
                "Accept": "application/json"
            }
        });
        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/json');

        expect(res.data.title).to.equal('My test');
    });

    it('loads elementSpec as json', async function () {
        const res = await util.axios.get('odd/docbook.odd', {
            params: {
                "ident": "code"
            }
        });
        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/json');

        expect(res.data.status).to.equal('found');
        expect(res.data.models.length).to.be.at.least(1);
    });

    it('deletes odd', function (done) {
        util.axios.request({
            url: 'odd/testme.odd',
            method: 'delete'
        })
        .catch((error) => {
            expect(error.response.status).to.equal(410);
            expect(error.response).to.satisfyApiSpec;
            done();
        })
    });

    after(util.logout);
});

describe('/api/odd/{odd} [not authenticated]', function () {
    it('tries to delete odd', function (done) {
        util.axios.request({
            url: 'odd/teipublisher.odd',
            method: 'delete'
        })
        .catch((error) => {
            expect(error.response.status).to.equal(401);
            done();
        });
    });

    it('tries to create new odd', function (done) {
        util.axios.request({
            url: 'odd/testme',
            method: 'post',
            params: {
                "title": "My test"
            }
        })
        .catch((error) => {
            expect(error.response.status).to.equal(401);
            expect(error.response).to.satisfyApiSpec;
            done();
        });
    });
});

describe('/api/odd [authenticated]', function () {

    before(util.login);


    it('retrieves a list of odds', async function() {
        const res = await util.axios.get('odd');
        const publisherOdd = [{
            "path": "/db/apps/tei-publisher/odd/teipublisher.odd",
            "name": "teipublisher",
            "canWrite": true,
            "label": "TEI Publisher Base",
            "description": "Base ODD from which all other ODDs inherit"
          }]
        expect(res.status).to.equal(200);
        expect(res.data).to.be.an('array').that.has.members;
        expect(res.data).to.include.deep.members(publisherOdd, 'teipublisher.odd not found');
        expect(res.data[1]).to.have.property('name');
        expect(res.data[1]).to.have.property('path');
        expect(res).to.satisfyApiSpec;
    });

    // it('regenerates all odds', async function() {
    //     // regenerating ODDs usually takes around 30000ms
    //     this.timeout(90000);

    //     const res = await util.axios.post('odd');
    //     expect(res.status).to.equal(200);
    //     expect(res.data).to.be.a('string').that.includes('/db/apps/tei-publisher/transform/teipublisher-web.xql: OK');
    //     expect(res.data).to.not.include('Error for output mode');
    //     expect(res).to.satisfyApiSpec;
    // });

    it('regenerates dta odd', async function() {
        this.timeout(10000);
        const res = await util.axios.request({
            url: 'odd',
            method: 'post',
            params: {
                "odd": "dta.odd",
                "check": true
            }
        });
        expect(res.status).to.equal(200);
        expect(res.data).to.be.a('string').that.includes('dta-web.xql: OK');
        expect(res.data).to.include('dta-print.xql: OK');
        expect(res.data).to.include('dta-latex.xql: OK');
        expect(res.data).to.include('dta-epub.xql: OK');
        expect(res.data).to.not.include('teipublisher-web.xql: OK');
        expect(res.data).to.not.include('Error for output mode');
        expect(res).to.satisfyApiSpec;
    });

    after(util.logout);
});

describe('/api/odd [not authenticated]', function () {
    this.timeout(30000);
    it('tries to regenerate dta odd without authorization', function(done) {
        util.axios.request({
            url: 'odd',
            method: 'post',
            params: {
                "odd": "dta.odd",
                "check": true
            }
        })
        .catch(function(error) {
            expect(error.response.status).to.equal(401);
            done();
        });
    });
});