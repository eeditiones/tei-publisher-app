const path = require('path');
const util = require('./util.js');
const fs = require('fs');
const tmp = require('tmp');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');

const server = 'http://localhost:8080/exist/apps/tei-publisher/api';

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

let konigsberg = [{
    "text": "koͤnigsberg",
    "value": "koͤnigsberg"
  }];

let bogactwa = [{
    "text": "bogactwa",
    "value": "bogactwa"
  }];

let kant = [{
    "text": "kant",
    "value": "kant"
  }];

let purchas = [{
    "text": "purchas",
    "value": "purchas"
  }]

describe('/api/search/autocomplete', function () {
    this.slow(2000);

    it('retrieves suggestions for default field', async function () {
        const res = await util.axios.get('search/autocomplete', {
            params: {
                query: 'koͤnig'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data).to.be.an('array').that.has.members;
        expect(res.data[0]).to.have.property('text');
        expect(res.data[0]).to.have.property('value');
        expect(res.data).to.include.deep.members(konigsberg, 'suggestion from Critik... not found');
        expect(res.data).to.not.include.deep.members(bogactwa, 'suggestion starting with a different prefix unexpectedly found');
        expect(res).to.satisfyApiSpec;
    });

    it('retrieves suggestions for author field', async function () {
        const res = await util.axios.get('search/autocomplete', {
            params: {
                query: 'k',
                field: 'author'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data).to.be.an('array').that.has.members;
        expect(res.data[0]).to.have.property('text');
        expect(res.data[0]).to.have.property('value');
        expect(res.data).to.include.deep.members(kant, 'suggestion for Kant not found');
        expect(res.data).to.not.include.deep.members(konigsberg, 'suggestion from Critik... text unexpectedly found');
        expect(res.data).to.not.include.deep.members(purchas, 'suggestion for Samuel Purchas unexpectedly found');
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/search', function () {
    this.timeout(30000);

    it('runs a search', async function () {
        const res = await util.axios.get('search', {
            params: {
                query: 'power'
            }
        });
        expect(res.status).to.equal(200);
        expect(res.headers['pb-total']).to.equal('89');
        expect(res).to.satisfyApiSpec;
    });
    it('retrieves next page', async function () {
        const res = await util.axios.get('search', {
            params: {
                query: 'power',
                start: 10
            }
        });
        expect(res.status).to.equal(200);
        expect(res.headers['pb-total']).to.equal('89');
        expect(res.headers['pb-start']).to.equal('10');
        expect(res.data).to.have.string('<div class="count">10</div>');
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/search/facets', function () {
    this.timeout(30000);

    let cookie;

    it('runs a search and retrieves facet counts for search results', async function () {
        const res = await util.axios.get('search', {
            params: {
                query: 'konwenanse'
            }
        });
        expect(res.status).to.equal(200);
        expect(res.headers['pb-total']).to.equal('1');
        expect(res.data).to.have.string('<div class="count">1</div>');

        const cookieHeader = res.headers["set-cookie"];
        cookie = cookieHeader[0];

        expect(res).to.satisfyApiSpec;
    });

    it('get facets', async function () {
        const res = await util.axios.get('search/facets', {
            headers: {
                "Cookie": cookie
            }
        });
        expect(res.status).to.equal(200);
        expect(res.data).to.have.string('Spanish');
        expect(res).to.satisfyApiSpec;
    });
});