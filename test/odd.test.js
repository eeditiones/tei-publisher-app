const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');

const server = 'http://localhost:8080/exist/apps/tei-publisher/api/';

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

let axiosInstance = axios.create({
    baseURL: server,
    headers: {
        "Origin": "http://localhost:8080"
    },
    withCredentials: true
});

describe('/api/odd/{odd} [authenticated]', function () {

    before(async function() {
        console.log('Logging in user ...');
        const res = await axiosInstance.request({
            url: 'login',
            method: 'post',
            params: {
                "user": "tei",
                "password": "simple"
            }
        });
        expect(res.status).to.equal(200);
        expect(res.data.user).to.equal('tei');

        const cookie = res.headers["set-cookie"];
        axiosInstance.defaults.headers.Cookie = cookie[0];
        console.log('Logged in as %s: %s', res.data.user, res.statusText);
    });

    it('creates new odd', async function () {
        this.timeout(10000);
        const res = await axiosInstance.request({
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
        const res = await axiosInstance.get('odd/testme.odd');
        expect(res.status).to.equal(200);
        expect(res.data).to.match(/schemaSpec/);
        expect(res).to.satisfyApiSpec;
    });

    it('deletes odd', function (done) {
        axiosInstance.request({
            url: 'odd/testme.odd',
            method: 'delete'
        })
        .catch((error) => {
            expect(error.response.status).to.equal(410);
            expect(error.response).to.satisfyApiSpec;
            done();
        })
    });

    after(function (done) {
        console.log('Logging out ...');
        axiosInstance.request({
            url: 'login',
            method: 'get',
            params: {
                "logout": "true"
            }
        })
        .catch((error) => {
            expect(error.response.status).to.equal(401);
            done();
        });
    });
});

describe('/api/odd/{odd} [not authenticated]', function () {
    it('tries to delete odd', function (done) {
        axiosInstance.request({
            url: 'odd/teipublisher.odd',
            method: 'delete'
        })
        .catch((error) => {
            expect(error.response.status).to.equal(500);
            done();
        });
    });

    it('tries to create new odd', function (done) {
        axiosInstance.request({
            url: 'odd/testme',
            method: 'post',
            params: {
                "title": "My test"
            }
        })
        .catch((error) => {
            expect(error.response.status).to.equal(403);
            expect(error.response).to.satisfyApiSpec;
            done();
        });
    });
});