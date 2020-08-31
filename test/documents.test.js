const path = require('path');
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

describe('/api/document/{id}/html', function () {
    it('retrieves as html', async function () {
        const res = await axiosInstance.get('document/test%2Fcortes_to_dantiscus.xml/html');

        expect(res.status).to.equal(200);
        expect(res.data).to.match(/title/);
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/parts/{id}/json', function () {
    it('retrieves as json', async function () {
        const res = await axiosInstance.get('parts/test%2Fcortes_to_dantiscus.xml/json', {
            params: {
                view: 'div'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data.odd).to.equal('dantiscus.odd');
        expect(res).to.satisfyApiSpec;
    });
});