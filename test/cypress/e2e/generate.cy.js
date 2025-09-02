// StandardJS, should-style assertions
// Use a unique app identifier per run to avoid collisions across runs

const baseOptions = {
  odd: ['dta'],
  title: 'DTA Test',
  template: 'view.html',
  'default-view': 'div',
  index: 'tei:div',
  owner: 'tei-demo',
  password: 'demo'
}

let app // { abbrev, uri }
let createOptions

describe('/api/apps/generate [authenticated]', () => {
  before(() => {
    cy.login()
    const suffix = `${Date.now()}`.slice(-6)
    const abbrev = `dta-test-${suffix}`
    app = { abbrev, uri: `http://exist-db.org/apps/${abbrev}` }
    createOptions = { ...baseOptions, abbrev: app.abbrev, uri: app.uri }
  })

  it('generates new application', () => {
    cy.api({ method: 'POST', url: '/api/apps/generate', body: createOptions })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body.target).to.eq(`/db/apps/${app.abbrev}`)
      })
  })

  it('has new application installed', () => {
    const query = [
      'declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";',
      'declare option output:method "json";',
      'declare option output:media-type "application/json";',
      'array { repo:list() }'
    ].join('\n')
    cy.request(`http://localhost:8080/exist/rest/db?_query=${encodeURIComponent(query)}&_wrap=no`)
      .then(({ status, body }) => {
        cy.wrap(status).should('eq', 200)
        cy.wrap(body).should('include', app.uri)
      })
  })

  it('can access new application', () => {
    cy.request(`http://localhost:8080/exist/apps/${app.abbrev}/index.html`)
      .its('status').should('eq', 200)
  })

  it('uploads a document to new application', () => {
    cy.readFile('data/test/kant_rvernunft_1781.TEI-P5.xml', 'utf8').then(xml => {
      const boundary = '----CYPRESSFORM' + Date.now()
      const body = [
        `--${boundary}\r\n` +
        'Content-Disposition: form-data; name="files[]"; filename="kant_rvernunft_1781.TEI-P5.xml"\r\n' +
        'Content-Type: application/xml\r\n\r\n' +
        xml + '\r\n' +
        `--${boundary}--\r\n`
      ].join('')
      cy.request({
        method: 'POST',
        url: `http://localhost:8080/exist/apps/${app.abbrev}/api/upload`,
        headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}` },
        body,
        auth: { user: 'tei-demo', pass: 'demo' }
      }).then(({ body }) => {
        expect(body).to.have.length(1)
        expect(body[0].name).to.eq(`/db/apps/${app.abbrev}/data/kant_rvernunft_1781.TEI-P5.xml`)
      })
    })
  })

  it('downloads application xar', () => {
    cy.request({ url: `http://localhost:8080/exist/apps/${app.abbrev}/api/apps/download`, encoding: 'binary' }).then(({ status, headers, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(headers['content-type']).should('include', 'application/zip')
      cy.wrap((body || '').length).should('be.gt', 0)
    })
  })

  it('uninstalls application', () => {
    const query = `repo:undeploy('${app.uri}'), repo:remove('${app.uri}')`
    cy.request({
      url: `http://localhost:8080/exist/rest/db?_query=${encodeURIComponent(query)}&_wrap=no`,
      auth: { user: 'admin', pass: '' }
    }).then(({ status, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(body).should('match', /result="ok"/)
    })
  })
})

describe('/api/apps/generate [not authenticated]', () => {
  it('should fail to generate new application', () => {
    const unauth = { ...baseOptions, abbrev: 'dta-test-unauth', uri: 'http://exist-db.org/apps/dta-test-unauth' }
    cy.api({ method: 'POST', url: '/api/apps/generate', body: unauth, failOnStatusCode: false })
      .its('status').should('be.oneOf', [401, 500])
  })
})
