const path = require('path');
const fs = require('fs');
const tmp = require('tmp');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');

const server = 'http://localhost:8080/exist/apps/tei-publisher/api';

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

const axiosInstance = axios.create({
    baseURL: server,
    headers: {
        "Origin": "http://localhost:8080"
    },
    withCredentials: true
});

describe('/api/collection', function () {
    this.slow(2000);

    it('retrieves document list for default data collection', async function () {
        const res = await axiosInstance.get('collection');

        expect(res.status).to.equal(200);
        expect(res.data).to.be.a('string').that.includes('TEI Publisher Demo Collection');
        expect(res.data).to.be.a('string').that.includes('Playground');
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/collection/{path}', function () {
    this.slow(2000);
    
    it('retrieves document list for test collection', async function () {
        const res = await axiosInstance.get('collection/test');

        expect(res.status).to.equal(200);
        expect(res.data).to.be.a('string').that.includes('Up');
        expect(res.data).to.be.a('string').that.includes('Bogactwa mowy polskiej');
        expect(res).to.satisfyApiSpec;
    });
});