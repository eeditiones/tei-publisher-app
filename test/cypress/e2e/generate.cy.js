// StandardJS, should-style assertions
// Port of generate tests, but skipped to avoid modifying the instance

const createOptions = {
  odd: ['dta'],
  uri: 'http://exist-db.org/apps/dta-test',
  abbrev: 'dta-test',
  title: 'DTA Test',
  template: 'view.html',
  'default-view': 'div',
  index: 'tei:div',
  owner: 'tei-demo',
  password: 'demo'
}

describe('/api/apps/generate [authenticated]', () => {
  beforeEach(() => {
    cy.login()
  })

  it('generates new application', () => {
    cy.api({ method: 'POST', url: '/api/apps/generate', body: createOptions })
      .its('status').should('eq', 200)

    cy.api({ method: 'POST', url: '/api/apps/generate', body: createOptions })
      .its('body.target').should('eq', '/db/apps/dta-test')
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
        cy.wrap(body).should('include', createOptions.uri)
      })
  })

  it('can access new application', () => {
    cy.request('http://localhost:8080/exist/apps/dta-test/index.html')
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
        url: 'http://localhost:8080/exist/apps/dta-test/api/upload',
        headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}` },
        body,
        auth: { user: 'tei-demo', pass: 'demo' }
      }).then(({ body }) => {
        cy.wrap(body).should('have.length', 1)
        cy.wrap(body[0].name).should('eq', '/db/apps/dta-test/data/kant_rvernunft_1781.TEI-P5.xml')
      })
    })
  })

  it('downloads application xar', () => {
    cy.request({
      url: 'http://localhost:8080/exist/apps/dta-test/api/apps/download',
      encoding: 'binary'
    }).then(({ status, headers, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(headers['content-type']).should('include', 'application/zip')
      cy.wrap((body || '').length).should('be.gt', 0)
    })
  })

  it('uninstalls application', () => {
    const query = "repo:undeploy('http://exist-db.org/apps/dta-test'), repo:remove('http://exist-db.org/apps/dta-test')"
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
    cy.api({ method: 'POST', url: '/api/apps/generate', body: createOptions, failOnStatusCode: false })
      .its('status').should('be.oneOf', [401, 500])
  })
})

