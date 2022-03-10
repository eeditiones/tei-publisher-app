const util = require('./util.js');
const path = require('path');
const axios = require('axios');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

describe('/api/dts', function () {
    it('queries entry point', async function() {
        const res = await util.axios.get('dts');
        expect(res.status).to.equal(200);
        expect(res.data['@type']).to.equal('EntryPoint');
        expect(res).to.satisfyApiSpec;
    });
});

let downloadLink;

describe('/api/dts/collection', function () {
    it('gets default collection', async function () {
        const res = await util.axios.get('dts/collection');
        expect(res.status).to.equal(200);
        expect(res.data['@type']).to.equal('Collection');
        expect(res.data.member.length).to.be.greaterThan(1);
        expect(res).to.satisfyApiSpec;
    });

    it('navigates to child collection', async function () {
        const res = await util.axios.get('dts/collection?id=https://teipublisher.com/dts/demo&nav=children&per-page=50');
        expect(res.status).to.equal(200);
        expect(res.data['@type']).to.equal('Collection');
        expect(res.data.member.length).to.be.greaterThan(1);
        expect(res).to.satisfyApiSpec;

        const member = res.data.member.find((m) => m['@id'] === 'https://teipublisher.com/dts/demo/let695.xml');
        expect(member).to.exist;
        expect(member).to.have.property('dts:passage');
        downloadLink = new URL(member['dts:passage'], 'http://localhost:8080').toString();
    });
});

describe('/api/dts/document', function () {
    before(util.login);
    it('retrieves resource', async function () {
        console.log('Loading resource from %s', downloadLink);
        const res = await axios.get(downloadLink);
        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/xml');
        expect(res).to.satisfyApiSpec;
    });

    it('imports resource', async function () {
        const res = await util.axios.get('dts/import', {
            params: {
                "uri": downloadLink,
                "temp": true
            }
        });
        expect(res.status).to.equal(201);
        expect(res.headers['content-type']).to.equal('application/json');
        expect(res.data).to.have.property('path');
        expect(res).to.satisfyApiSpec;
    });
    after(util.logout);
});