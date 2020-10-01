const util = require('./util.js');
const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

describe('/api/version', function () {
    it('queries version information', async function () {
        const res = await util.axios.get('version');
        expect(res.status).to.equal(200);
        expect(res.data).to.have.property('api');
        expect(res.data).to.have.property('app');
        expect(res.data.app.name).to.equal('tei-publisher');
        expect(res).to.satisfyApiSpec;
    });
});