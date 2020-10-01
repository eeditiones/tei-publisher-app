const path = require('path');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const util = require('./util.js');

const spec = path.resolve("./modules/lib/api.json");
chai.use(chaiResponseValidator(spec));

let doc = [{
    "name": "documentation.html",
    "title": "Documentation"
  }]

describe('/api/templates [authenticated]', function () {

    before(util.login);

    it('retrieves a list of templates', async function () {
        this.timeout(10000);
        const res = await util.axios.get('templates');

        expect(res.status).to.equal(200);
        expect(res.data).to.be.an('array').that.has.members;
        expect(res.data).to.include.deep.members(doc, 'documentation template not found');
        expect(res).to.satisfyApiSpec;
    });

    after(util.logout);
});

describe('/api/templates [not authenticated]', function () {
    it('retrieves a list of templates', async function () {
        this.timeout(10000);
        const res = await util.axios.get('templates');
        expect(res.status).to.equal(200);
        expect(res.data).to.be.an('array').that.has.members;
        expect(res.data).to.include.deep.members(doc, 'documentation template not found');
        expect(res).to.satisfyApiSpec;
    });
});