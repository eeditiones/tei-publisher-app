const path = require('path');
const fs = require('fs');
const tmp = require('tmp');
const chai = require('chai');
const expect = chai.expect;
const chaiResponseValidator = require('chai-openapi-response-validator');
const axios = require('axios');
const pdfjsLib = require("pdfjs-dist/es5/build/pdf.js");
const jsdom = require("jsdom");
const { JSDOM } = jsdom;

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

describe('/api/document/{id}', function () {
    it('retrieves as xml', async function () {
        const res = await axiosInstance.get('document/test%2Fgraves6.xml');

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/xml');
        expect(res.data).to.contain('<date when="1957-11-15">November 15, 1957</date>');
        expect(res).to.satisfyApiSpec;
    });
    it('retrieves as markdown', async function () {
        const res = await axiosInstance.get('document/about.md');

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('text/markdown');
        expect(res.data).to.contain('# Markdown');
        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/document/{id}/html', function () {
    this.slow(4000);
    it('retrieves as html', async function () {
        const res = await axiosInstance.get('document/test%2Fcortes_to_dantiscus.xml/html', {
            params: {
                "base": "http://foo.com"
            }
        });

        expect(res.status).to.equal(200);
        const fragment = JSDOM.fragment(res.data);
        expect(fragment.querySelector('title')).to.exist;
        expect(fragment.querySelector('base[href="http://foo.com"]')).to.exist;
        expect(res).to.satisfyApiSpec;
    });

    it('retrieves part identified by xml:id as html', async function () {
        const res = await axiosInstance.get('document/doc%2Fdocumentation.xml/html', {
            params: {
                "id": "unix-installation"
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data).to.match(/Unix installation/);
        expect(res).to.satisfyApiSpec;
    });

    it('tries to retrieve non-existing document', function (done) {
        axiosInstance.get('document/foo%2Fbaz.xml/html')
            .catch((error) => {
                expect(error.response.status).to.equal(404);
                done();
            });
    });
});

describe('/api/document/{id}/print', function() {
    it('retrieves as HTML optimized for print', async function() {
        const res = await axiosInstance.get('document/test%2Forlik_to_serafin.xml/print', {
            params: {
                odd: "serafin.odd",
                base: "%2Fexist%2Fapps%2Ftei-publisher%2Ftest",
                style: ['resources%2Ffonts%2Ffont.css', 'resources%2Fcss%2Fprint.css']
            }
        });
        expect(res.status).to.equal(200);
        const fragment = JSDOM.fragment(res.data);
        expect(fragment.querySelector('.doc-title')).to.exist;
        expect(fragment.querySelector('.register h1')).to.exist;
    });
});

describe('/api/document/{id}/tex', function () {
    this.slow(4000);
    it('retrieves as PDF transformed via LaTeX', async function () {
        const res = await axiosInstance.get('document/test%2Fcortes_to_dantiscus.xml/tex', {
            params: {
                "source": "true"
            }
        });

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/x-latex');
        
        expect(res).to.satisfyApiSpec;
    });
});

describe.skip('/api/document/{id}/pdf', function () {
    this.slow(4000);
    it('retrieves as PDF transformed via FO', async function () {
        const token = new Date().toISOString();
        const res = await axiosInstance.get('document/test%2Fgraves6.xml/pdf', {
            params: {
                "token": token
            }
        });

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('media-type=application/pdf');

        const cookies = res.headers["set-cookie"];
        expect(cookies).to.include(`simple.token=${token}`);

        const pdf = await pdfjsLib.getDocument({data: res.data}).promise;
        expect(pdf.numPages).to.equal(2);
    });

    it('retrieves FO output', async function () {
        const res = await axiosInstance.get('document/test%2Fgraves6.xml/pdf', {
            params: {
                "source": true
            }
        });

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/xml');

        expect(res).to.satisfyApiSpec;
    });
});

describe('/api/document/{id}/epub', function () {
    this.slow(2000);
    it('retrieves as EPub', async function () {
        const token = new Date().toISOString();
        const res = await axiosInstance.get('document/test%2Fcortes_to_dantiscus.xml/epub', {
            params: {
                "token": token
            },
            responseType: 'stream'
        });

        expect(res.status).to.equal(200);
        expect(res.headers['content-type']).to.equal('application/epub+zip');
        
        const cookies = res.headers["set-cookie"];
        expect(cookies).to.include(`simple.token=${token}`);

        const tempFile = tmp.tmpNameSync();
        res.data.pipe(fs.createWriteStream(tempFile));
        res.data.on('end', function() {
            const stats = fs.statSync(tempFile);
            expect(stats.size).to.be.greaterThan(0);
        });
    });

    it('tries to retrieve non-existing document', function (done) {
        axiosInstance.get('document/foo%2Fbaz.xml/epub')
            .catch((error) => {
                expect(error.response.status).to.equal(404);
                done();
            });
    });
});

describe('/api/document/{id}/content', function () {
    it('retrieves table of content', async function () {
        const res = await axiosInstance.get('document/doc%2Fdocumentation.xml/contents', {
            params: {
                view: 'div'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data).to.match(/<pb-link.*>Introduction<\/pb-link>/);
        expect(res).to.satisfyApiSpec;
    });

    it('tries to get table of content of non-existing document', function (done) {
        axiosInstance.get('document/foo%2Fbaz.xml/contents')
            .catch((error) => {
                expect(error.response.status).to.equal(404);
                done();
            });
    });
});

describe('/api/parts/{id}/json', function () {
    it('retrieves document part as json', async function () {
        const res = await axiosInstance.get('parts/test%2Fcortes_to_dantiscus.xml/json', {
            params: {
                view: 'div'
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data.odd).to.equal('dantiscus.odd');
        expect(res).to.satisfyApiSpec;
    });

    it('retrieves part identified by xpath as json', async function () {
        const res = await axiosInstance.get('parts/test%2Fcortes_to_dantiscus.xml/json', {
            params: {
                "view": "single",
                "xpath": "//front"
            }
        });

        expect(res.status).to.equal(200);
        expect(res.data.doc).to.equal("cortes_to_dantiscus.xml");
        expect(res.data.content).to.match(/<front .*>/);
        expect(res).to.satisfyApiSpec;
    });

    it('tries to retrieve non-existing document', function (done) {
        axiosInstance.get('parts/foo%2Fbaz.xml/json')
            .catch((error) => {
                expect(error.response.status).to.equal(404);
                done();
            });
    });
});